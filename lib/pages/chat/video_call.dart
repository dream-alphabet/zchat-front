import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/event_bus.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/model/contact.dart';

// 视频通话页面
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  // 本地webrtc渲染
  final _localRenderer = RTCVideoRenderer();

  // 远程webrtc渲染
  final _remoteRenderer = RTCVideoRenderer();

  // 是否接听
  bool _isAccept = false;

  // 是否是通话发起者
  bool _isCaller = false;

  // 消息id
  int _messageId = -1;

  // 同意接听按钮是否处于加载中
  bool _isAgreeing = false;

  // 联系人id
  String _contactId = '';

  // 联系人信息
  ContactInfoRes? _contactInfo;

  // 媒体流
  MediaStream? _localStream;

  // webrtc核心对象
  RTCPeerConnection? _peerConnection;

  // 监听websocket服务器推送的消息
  late StreamSubscription<ServerMsgEvent> _streamSubscription;

  // 暂存接收到的 Offer SDP 数据
  dynamic _pendingOffer;

  // 暂存接收到的candidate候选信息
  final List<RTCIceCandidate> _pendingCandidates = [];

  // 最大重连次数
  final int _maxRetryCount = 2;
  // 当前已重试次数
  int _retryCount = 0;
  // 是否正在重试中
  bool _isRetrying = false;
  // 是否主动挂断
  bool _isManualHangup = false;
  // 重连延迟定时器
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    // 接收参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        _isCaller = params['isCaller'];
        _messageId = params['messageId'];
        _getContactInfo();
      }
    }).then((_) {
      _initRenderer();
      _getUserMedia();
      // 监听服务器推送消息事件
      _streamSubscription = eventBus
          .on<ServerMsgEvent<ChatMessageRes>>()
          .listen((event) {
            // 消息类型不是聊天消息，直接返回
            if (event.type != ServerMsgType.chat) {
              return;
            }
            final msg = event.msg;
            // 如果是对方发送的信令
            if (msg.messageType == MessageTypeEnum.rtcSignal.type) {
              // 信令消息
              final signal = jsonDecode(msg.messageContent);
              final signalType = signal['type'];
              final signalData = signal['data'];
              // 接收offer, 暂存offer sdp数据
              if (signalType == RTCSignalEnum.offer) {
                setState(() {
                  _pendingOffer = signalData;
                });
              } else if (signalType == RTCSignalEnum.answer) {
                // 接收answer
                _receiveAnswer(signalData);
              } else if (signalType == RTCSignalEnum.candidate) {
                // 接收candidate
                _receiveCandidate(signalData);
              } else if (signalType == RTCSignalEnum.callEnd) {
                // 对方已挂断
                _beCallEnd();
              }
            }
          });
    });
  }

  // 获取联系人信息
  Future<void> _getContactInfo() async {
    final contactInfo = await getContactInfoApi(_contactId);
    // 结果为空
    if (contactInfo == null) {
      ToastUtils.showGlobalToast(msg: '没有查询到该联系人信息');
      Navigator.pop(context);
      return;
    }
    _contactInfo = contactInfo;
    setState(() {});
  }

  // 初始化渲染
  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // 获取本地媒体流
  Future<void> _getUserMedia() async {
    // 获取媒体流之前先请求权限
    final isPermitted = await _requestPermission();
    if (!isPermitted) {
      return;
    }
    // 媒体约束
    final constraints = {
      // 启用视频流
      'video': true,
      'audio': true,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _localRenderer.srcObject = _localStream;
    await _setupPeerConnection();
    // 如果是呼叫方，主动发起offer
    if (_isCaller) {
      _sendOffer();
    }
    setState(() {});
  }

  // 创建并配置PeerConnection（重连时复用）
  Future<void> _setupPeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:${GlobalConstants.host}:3478'},
        {
          'urls': 'turn:${GlobalConstants.host}:3478',
          'username': 'dream',
          'credential': '239856',
        },
        {
          'urls': 'turn:${GlobalConstants.host}:3478?transport=tcp',
          'username': 'dream',
          'credential': '239856',
        },
      ],
      // 添加这些配置增强连通性
      'iceTransportPolicy': 'all', // 允许所有候选类型
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    });
    // 将本地媒体流的所有轨道添加到连接中
    _localStream!.getTracks().forEach((track) {
      // 一定要加_localStream
      _peerConnection!.addTrack(track, _localStream!);
    });
    // 设置事件监听
    // 监听ICE候选收集状态
    _peerConnection!.onIceGatheringState = (state) {
      print('ICE收集状态: $state');
    };
    // 监听本地ice候选生成
    _peerConnection!.onIceCandidate = (e) {
      if (e.candidate != null) {
        // 解析候选类型和地址用于调试
        final candidateStr = e.candidate!;
        final typeMatch = RegExp(r'typ (\w+)').firstMatch(candidateStr);
        final addrMatch =
            RegExp(r'(\d+\.\d+\.\d+\.\d+)').firstMatch(candidateStr);
        final type = typeMatch?.group(1) ?? 'unknown';
        final addr = addrMatch?.group(1) ?? 'unknown';
        print('ICE候选: $type $addr (mid=${e.sdpMid})');
        // 发送candidate
        _sendRTCSignal(RTCSignalEnum.candidate, e.toMap());
      }
    };
    // 监听ICE连接状态变化
    _peerConnection!.onConnectionState = (state) async {
      print('ICE连接状态: $state');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          // 连接成功，取消重连定时器并重置重试计数
          _reconnectTimer?.cancel();
          _retryCount = 0;
          _isAccept = true;
          // 发送established信令，告知服务器连接已建立
          if (_isCaller) {
            _sendRTCSignal(RTCSignalEnum.established, {'messageId': _messageId});
          }
          setState(() {});
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          // ICE连接断开，等待3秒看是否能自动恢复
          print('WebRTC ICE断开，等待自动恢复...');
          _startReconnectDelay();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          // ICE完全失败，立即重试
          print('WebRTC连接失败，尝试重连...');
          _reconnectTimer?.cancel();
          _tryRetryConnection();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          // 主动关闭，不重试
          break;
        default:
      }
    };
    // 当远程视频流加入时
    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteRenderer.srcObject = event.streams[0];
        setState(() {});
      }
    };
  }

  // 延迟后触发重连（用于Disconnected状态，给ICE自动恢复留时间）
  void _startReconnectDelay() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _tryRetryConnection();
    });
  }

  // 尝试重连，判断是否满足重连条件
  void _tryRetryConnection() {
    // 主动挂断不重连
    if (_isManualHangup) return;
    // 已经在重试中，不重复触发
    if (_isRetrying) return;
    // 超过最大重试次数
    if (_retryCount >= _maxRetryCount) {
      print('WebRTC重连已用尽重试次数($_maxRetryCount次)，放弃重连');
      // 主动挂断
      _callEnd();
      ToastUtils.showGlobalToast(msg: '连接失败，请稍后重试');
      Navigator.pop(context);
      return;
    }
    _retryConnection();
  }

  // 执行WebRTC重连
  Future<void> _retryConnection() async {
    _isRetrying = true;
    _retryCount++;
    print('WebRTC重连尝试 $_retryCount/$_maxRetryCount');

    // 清理旧的PeerConnection
    await _peerConnection?.close();
    _peerConnection?.dispose();

    // 重新创建PeerConnection
    await _setupPeerConnection();

    // 根据角色重新发起协商
    if (_isCaller) {
      // 呼叫方：重新发送offer
      await _sendOffer();
    } else if (_pendingOffer != null) {
      // 被叫方：如果有暂存的offer，重新发送answer
      await _sendAnswer(_pendingOffer);
    }

    _isRetrying = false;
  }

  // 发送webrtc信令
  Future<void> _sendRTCSignal(String signalType, dynamic data) async {
    // 信令内容
    final msg = {'type': signalType, 'data': data};
    // 发送消息
    await sendMessageApi(
      SendMsgReq(
        contactId: _contactId,
        contactType: UserContactTypeEnum.user,
        messageType: MessageTypeEnum.rtcSignal.type,
        messageContent: jsonEncode(msg),
      ),
    );
  }

  // 发送offer
  Future<void> _sendOffer() async {
    // 创建offer
    final offer = await _peerConnection!.createOffer();
    // 设置本地媒体流
    await _peerConnection!.setLocalDescription(offer);
    // 发送offer到信令服务器
    await _sendRTCSignal(RTCSignalEnum.offer, offer.toMap());
  }

  // 发送answer
  Future<void> _sendAnswer(dynamic offer) async {
    // 1. 先设置远程描述
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    // 2. 再创建 answer
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // 3. 最后发送 answer
    await _sendRTCSignal(RTCSignalEnum.answer, answer.toMap());
    print('已设置远程sdp, 添加缓存的candidate');
    // 添加缓存的候选
    for (var c in _pendingCandidates) {
      await _peerConnection!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  // 接收candidate
  Future<void> _receiveCandidate(dynamic data) async {
    final candidate = RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );
    // 如果远程描述未设置，则缓存
    final remoteDescription = await _peerConnection?.getRemoteDescription();
    if (remoteDescription == null) {
      print('远程sdp为空，缓存candidate: $candidate');
      _pendingCandidates.add(candidate);
      return;
    }
    await _peerConnection!.addCandidate(candidate);
  }

  // 接收answer
  Future<void> _receiveAnswer(dynamic answer) async {
    // 设置远程sdp
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
    print('已设置远程sdp, 添加缓存的candidate');
    // 添加缓存的候选
    for (var c in _pendingCandidates) {
      await _peerConnection!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  // 请求摄像头和麦克风权限
  Future<bool> _requestPermission() async {
    final res = await [Permission.camera, Permission.microphone].request();
    for (final status in res.values) {
      // 如果有权限被拒绝
      if (status.isDenied) {
        ToastUtils.showGlobalToast(
          msg: '未授予权限',
          duration: Duration(milliseconds: 1500),
        );
        Navigator.pop(context);
        return false;
      }
    }
    return true;
  }

  // 被动挂断通话
  Future<void> _beCallEnd() async {
    // 标记为主动挂断，阻止重连逻辑
    _isManualHangup = true;
    _reconnectTimer?.cancel();
    // 断开连接
    await _peerConnection?.close();
    await ToastUtils.showGlobalToastAsync(
      msg: '对方已挂断',
      duration: Duration(seconds: 1),
    );
    // 清空暂存的offer
    _pendingOffer = null;
    Navigator.pop(context);
  }

  // 主动挂断通话
  void _callEnd() async {
    // 标记为主动挂断，阻止重连逻辑
    _isManualHangup = true;
    _reconnectTimer?.cancel();
    await _sendRTCSignal(RTCSignalEnum.callEnd, null);
    // 断开连接
    await _peerConnection?.close();
    await ToastUtils.showGlobalToastAsync(
      msg: '已挂断',
      duration: Duration(seconds: 1),
    );
    // 清空暂存的offer
    _pendingOffer = null;
    Navigator.pop(context);
  }

  // 构建同意接听按钮
  Widget _buildAgreeCallBtn() {
    return GestureDetector(
      onTap: _isAgreeing
          ? null // 加载中时禁止重复点击
          : () {
              setState(() {
                _isAgreeing = true; // 进入加载状态
              });
              // 正常流程：如果呼叫方已经发送了offer, 那么可以发送answer
              if (_pendingOffer != null) {
                _sendAnswer(_pendingOffer);
              } else {
                // 容错处理：如果没收到 Offer 却点了接听，则作为发起方发送 Offer
                _sendOffer();
              }
            },
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(shape: .circle, color: Colors.green),
        alignment: .center,
        // 加载中显示旋转指示器，否则显示电话图标
        child: _isAgreeing
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.call, color: Colors.white, size: 30.w),
      ),
    );
  }

  // 构建挂断按钮
  Widget _buildCallEndBtn() {
    return GestureDetector(
      onTap: _callEnd,
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(shape: .circle, color: Colors.red),
        alignment: .center,
        child: Icon(Icons.call_end_rounded, color: Colors.white, size: 30.w),
      ),
    );
  }

  // 构建控制按钮区域
  Widget _buildControl() {
    if (_isAccept) {
      return Center(child: _buildCallEndBtn());
    }
    return _isCaller
        ? Center(child: _buildCallEndBtn())
        : Row(
            mainAxisAlignment: .spaceEvenly,
            children: [_buildCallEndBtn(), _buildAgreeCallBtn()],
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.light, // 底部导航栏图标颜色
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 底部全屏显示(接听时是对方，等待中是自己)
            Positioned.fill(
              child: RTCVideoView(
                _isAccept ? _remoteRenderer : _localRenderer,
                objectFit: .RTCVideoViewObjectFitCover,
                filterQuality: .medium,
              ),
            ),
            // 等待中显示联系人信息
            if (!_isAccept)
              Positioned(
                top: 100.w,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    spacing: 10.w,
                    crossAxisAlignment: .center,
                    children: [
                      ContactAvatar(contactId: _contactId, size: 50),
                      Text(
                        _contactInfo?.contactName ?? '',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),
              ),
            // 右上角的是用户自己(接听时才显示)
            if (_isAccept)
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: 150.w,
                  height: 180.w,
                  child: RTCVideoView(
                    _localRenderer,
                    objectFit: .RTCVideoViewObjectFitCover,
                    filterQuality: .medium,
                  ),
                ),
              ),
            Positioned(bottom: 30.w, left: 0, right: 0, child: _buildControl()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _streamSubscription.cancel();
    _peerConnection?.dispose();
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    _localStream?.dispose();
    super.dispose();
  }
}
