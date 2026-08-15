import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/call_tone.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/event_bus.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/model/contact.dart';

// 语音通话页面
class VoiceCallPage extends StatefulWidget {
  const VoiceCallPage({super.key});

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  // 是否接听
  bool _isAccept = false;

  // 是否打开麦克风
  bool _isMicOn = true;

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

  // 媒体流（仅音频轨道）
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
        // 启动铃声提示：呼叫方播放等待音，被叫方播放来电铃声
        if (_isCaller) {
          CallTone.startWaitingTone();
        } else {
          CallTone.startRingtone();
        }
      }
    }).then((_) {
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
                // 自己主动挂断时，忽略后端推送回来的挂断信令
                if (_isManualHangup) {
                  return;
                }
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

  // 获取本地音频流
  Future<void> _getUserMedia() async {
    // 获取媒体流之前先请求麦克风权限
    final isPermitted = await _requestPermission();
    if (!isPermitted) {
      return;
    }
    // 仅请求音频轨道，不请求视频
    final constraints = {
      'audio': {
        // 回声消除/降噪/自动增益，保证语音清晰
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
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
      // 预收集ICE候选，加速连接建立（减少接通等待时间）
      'iceCandidatePoolSize': 8,
    });
    // 将本地音频轨道添加到连接中
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
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
          // 接听成功，停止铃声并振动提示
          CallTone.stop();
          CallTone.vibrate();
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
  }

  // 延迟后触发重连（用于Disconnected状态，给ICE自动恢复留时间）
  void _startReconnectDelay() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _tryRetryConnection();
    });
  }

  // 尝试重连，判断是否满足重连条件
  Future<void> _tryRetryConnection() async {
    // 主动挂断不重连
    if (_isManualHangup) return;
    // 已经在重试中，不重复触发
    if (_isRetrying) return;
    // 超过最大重试次数
    if (_retryCount >= _maxRetryCount) {
      print('WebRTC重连已用尽重试次数($_maxRetryCount次)，放弃重连');
      // 异常挂断（_callEnd内部会挂断并退出页面）
      ToastUtils.showGlobalToast(msg: '连接失败，请稍后重试');
      await _callEnd(abnormal: true);
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
    // 设置本地媒体描述
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

  // 请求麦克风权限
  Future<bool> _requestPermission() async {
    final res = await [Permission.microphone].request();
    for (final status in res.values) {
      // 如果有权限被拒绝
      if (status.isDenied) {
        ToastUtils.showGlobalToast(
          msg: '未授予麦克风权限',
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
    // 停止铃声并振动提示
    CallTone.stop();
    CallTone.vibrate();
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

  // 主动挂断通话（abnormal=true表示异常挂断，如重连失败）
  Future<void> _callEnd({bool abnormal = false}) async {
    // 标记为主动挂断，阻止重连逻辑
    _isManualHangup = true;
    _reconnectTimer?.cancel();
    // 停止铃声并振动提示
    CallTone.stop();
    CallTone.vibrate();
    await _sendRTCSignal(RTCSignalEnum.callEnd, {
      'messageId': _messageId,
      'abnormal': abnormal,
    });
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

  // 打开/关闭麦克风（关闭后发送静音帧，对方听不到声音）
  void _toggleMic() {
    setState(() => _isMicOn = !_isMicOn);
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = _isMicOn;
    });
  }

  // 构建圆形控制按钮（微信风格：半透明深色底+白色图标，非激活时白底+黑色图标）
  Widget _buildControlBtn({
    required VoidCallback onTap,
    required IconData icon,
    required bool active,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: .circle,
          color: active
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.9),
        ),
        alignment: .center,
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.black,
          size: 24.w,
        ),
      ),
    );
  }

  // 构建麦克风开关按钮
  Widget _buildMicBtn() {
    return _buildControlBtn(
      onTap: _toggleMic,
      icon: _isMicOn ? Icons.mic : Icons.mic_off,
      active: _isMicOn,
    );
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
      // 通话中：麦克风开关 + 挂断
      return Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          _buildMicBtn(),
          _buildCallEndBtn(),
        ],
      );
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 联系人信息区域（居中）
            Positioned(
              top: 120.w,
              left: 0,
              right: 0,
              child: Column(
                spacing: 16.w,
                crossAxisAlignment: .center,
                children: [
                  ContactAvatar(contactId: _contactId, size: 60),
                  Text(
                    _contactInfo?.contactName ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 18.sp),
                  ),
                  Text(
                    _isAccept ? '通话中...' : '等待接听...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            // 控制按钮（底部居中）
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
    _localStream?.dispose();
    // 兜底停止铃声/振动（防止页面被意外关闭时铃声残留）
    CallTone.stop();
    super.dispose();
  }
}
