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
    final constraints = {'video': true, 'audio': true};
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _localRenderer.srcObject = _localStream;
    // 初始化PeerConnection
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
      'rtcpMuxPolicy': 'negotiate',
    });
    // 将本地媒体流的所有轨道添加到连接中
    _localStream!.getTracks().forEach((track) {
      // 一定要加_localStream
      _peerConnection!.addTrack(track, _localStream!);
    });
    // 设置事件监听
    // 监听本地ice候选生成
    _peerConnection!.onIceCandidate = (e) {
      if (e.candidate != null) {
        // 发送candidate
        _sendRTCSignal(RTCSignalEnum.candidate, e.toMap());
      }
    };
    // 监听ICE连接状态变化
    _peerConnection!.onConnectionState = (state) async {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _isAccept = true;
          setState(() {});
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          await ToastUtils.showGlobalToastAsync(msg: '已断开连接');
          Navigator.pop(context);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
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
    // 如果是呼叫方，主动发起offer
    if (_isCaller) {
      _sendOffer();
    }
    setState(() {});
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
  }

  // 接收candidate
  Future<void> _receiveCandidate(dynamic data) async {
    await _peerConnection!.addCandidate(
      RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
    );
  }

  // 接收answer
  Future<void> _receiveAnswer(dynamic answer) async {
    // 设置远程sdp
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
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
      onTap: () {
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
        child: Icon(Icons.call, color: Colors.white, size: 30.w),
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
    _streamSubscription.cancel();
    _peerConnection?.dispose();
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    _localStream?.dispose();
    super.dispose();
  }
}
