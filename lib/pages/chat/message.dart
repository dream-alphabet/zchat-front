import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/animation.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/emoji.dart';
import 'package:zchat/common/event_bus.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/common/voice_player.dart';
import 'package:zchat/common/websocket.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/model/enums/group.dart';
import 'package:zchat/pages/chat/widgets/chat_message.dart';
import 'package:zchat/pages/contact/contact_select.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/message.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/dialog.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/page_header.dart';

// 聊天消息页面
class ChatMessagePage extends StatefulWidget {
  const ChatMessagePage({super.key});

  @override
  State<ChatMessagePage> createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  // 联系人id(用户/群聊)
  String _contactId = '';

  // 联系人类型
  int _contactType = UserContactTypeEnum.user;

  // 会话id
  String _sessionId = '';

  // 消息store
  final _messageStore = Get.find<MessageController>();

  // 会话store
  final _sessionStore = Get.find<ChatSessionStore>();

  // 联系人store
  final _userContactController = Get.find<UserContactController>();

  // 联系人信息
  ContactInfoRes? _contactInfo;

  // 联系人名称
  String get _contactName {
    final contact = _userContactController.findUserContact(
      _contactId,
      _contactType,
    );
    if (contact == null) {
      return '';
    }
    return contact.contactName;
  }

  // 是否显示表情区域
  bool _showEmotion = false;

  // 是否显示更多区域
  bool _showMore = false;

  // 是否显示语音
  bool _showVoice = false;

  // 消息输入框控制器
  final _messageController = TextEditingController();

  // 消息输入框焦点控制器
  final _messageFocusNode = FocusNode();

  // 文本消息(ValueNotifier配合ValueListenableBuilder让输入行局部重建, 避免每次按键setState重建整个页面)
  final _msgNotifier = ValueNotifier<String>('');
  String get _msg => _msgNotifier.value;
  set _msg(String value) => _msgNotifier.value = value;

  // 是否显示机器人输入中气泡
  bool _showTyping = false;
  // 输入中气泡超时定时器
  Timer? _typingTimer;

  // 页码
  final _page = 1;

  // 每页条数
  final _pageSize = 15;

  // 最大消息id
  int? _maxMessageId;

  // 是否正在请求
  bool _isLoading = false;

  // 是否还有更多数据
  bool _hasMore = true;

  // 消息列表
  List<ChatMessageRes> _msgList = [];

  // 消息列表滚动控制器
  final _msgListController = ScrollController();

  // 定位目标消息id（搜索聊天记录跳转）
  int? _targetMessageId;
  // 定位后高亮的消息id
  int? _highlightMessageId;
  // 是否处于定位模式（显示回到最新悬浮条）
  bool _isLocated = false;
  // 消息GlobalKey（用于定位滚动）
  final Map<int, GlobalKey> _messageKeys = {};

  // 滚动加载防抖
  final _scrollDebouncer = Debouncer(timeout: Duration(milliseconds: 200));

  // 监听websocket服务器推送的消息
  late StreamSubscription<ServerMsgEvent> _streamSubscription;

  final _userController = Get.find<UserController>();

  // 录音器
  final _audioRecorder = AudioRecorder();

  // 是否正在录音
  bool _isRecording = false;

  // 是否处于取消发送状态(上滑)
  bool _recordCanceled = false;

  // 录音文件路径
  String _recordPath = '';

  // 录音时长(秒)
  int _recordDuration = 0;

  // 录音计时器
  Timer? _recordTimer;

  // 按住时手指起始y坐标(用于判断上滑取消)
  double _pressStartDy = 0;

  // 录音是否已结束(防止重复触发发送)
  bool _recordFinished = false;

  // 手指是否还按在按钮上(用于取消异步启动中的录音)
  bool _pressActive = false;

  // 是否多选模式
  bool _multiSelect = false;

  // 已选消息id集合
  final Set<int> _selectedIds = {};

  // 是否正在转发(防重复发送)
  bool _isForwarding = false;

  // 根据文件后缀获取文件类型
  FileTypeEnum _getFileType(String filePath) {
    final index = filePath.lastIndexOf('.');
    // 没有后缀名，默认其他文件
    if (index == -1) {
      return FileTypeEnum.file;
    }
    // 后缀名
    final ext = filePath.substring(index + 1);
    if (GlobalConstants.imageFormats.contains(ext)) {
      return FileTypeEnum.image;
    } else if (GlobalConstants.videoFormats.contains(ext)) {
      return FileTypeEnum.video;
    }
    return FileTypeEnum.file;
  }

  // 校验文件大小
  bool _validateFileSize(FileTypeEnum fileType, int fileSize) {
    switch (fileType) {
      case FileTypeEnum.image:
        if (fileSize > GlobalConstants.imageMaxSize) {
          ToastUtils.showGlobalToast(
            msg: '图片不能大于${GlobalConstants.imageMaxMB}MB',
          );
          return false;
        }
        return true;
      case FileTypeEnum.video:
        if (fileSize > GlobalConstants.videoMaxSize) {
          ToastUtils.showGlobalToast(
            msg: '视频不能大于${GlobalConstants.videoMaxMB}MB',
          );
          return false;
        }
        return true;
      case FileTypeEnum.file:
        if (fileSize > GlobalConstants.fileMaxSize) {
          ToastUtils.showGlobalToast(
            msg: '文件不能大于${GlobalConstants.fileMaxMB}MB',
          );
          return false;
        }
        return true;
    }
  }

  // 发送文件消息
  void _sendFile() async {
    // 选择文件(可以选择多个)
    final result = await FilePicker.pickFiles();
    // 用户选择了文件
    if (result != null && result.files.isNotEmpty) {
      final files = result.files;
      for (final file in files) {
        // 文件路径
        final filePath = file.path ?? '';
        // 文件大小
        final fileSize = file.size;
        // 文件名
        final filename = file.name;
        // 文件类型
        final fileType = _getFileType(filePath);
        // 校验文件大小
        if (!_validateFileSize(fileType, fileSize)) {
          return;
        }
        final multipart = await MultipartFile.fromFile(
          filePath,
          filename: filename,
        );
        // 发送消息
        final msg = await sendMessageApi(
          SendMsgReq(
            contactId: _contactId,
            contactType: _contactType,
            messageType: MessageTypeEnum.file.type,
            messageContent: fileType.messageContent,
            file: multipart,
          ),
        );
        setState(() {
          // 添加到发送后的消息到列表
          _msgList.insert(0, msg);
        });
        // 滚动到底部
        _scrollToBottom();
        // 更新会话的lastMessage和lastReceiveTime
        _sessionStore.updateLastMessage(
          _sessionId,
          fileType.messageContent,
          msg.sendTime,
        );
      }
    }
  }

  // 发送图片或视频消息(相册)
  void _sendMediaFromGallery(String mediaType) async {
    // 获取相册权限
    final status = await requestGalleryPermission();
    // 获取失败
    if (status.isDenied) {
      ToastUtils.showGlobalToast(msg: '没有权限');
      return;
    }
    // 从相册中获取图片或视频
    final picker = ImagePicker();
    XFile? media;
    if (mediaType == 'image') {
      media = await picker.pickImage(source: ImageSource.gallery);
    } else if (mediaType == 'video') {
      media = await picker.pickVideo(source: ImageSource.gallery);
    }
    if (media != null) {
      // 文件路径
      final filePath = media.path;
      // 文件大小
      final fileSize = await media.length();
      // 文件名
      final filename = media.name;
      // 文件类型
      final fileType = _getFileType(filePath);
      // 校验文件大小
      if (!_validateFileSize(fileType, fileSize)) {
        return;
      }
      final multipart = await MultipartFile.fromFile(
        filePath,
        filename: filename,
      );
      // 发送消息
      final msg = await sendMessageApi(
        SendMsgReq(
          contactId: _contactId,
          contactType: _contactType,
          messageType: MessageTypeEnum.file.type,
          messageContent: fileType.messageContent,
          file: multipart,
        ),
      );
      setState(() {
        // 添加到发送后的消息到列表
        _msgList.insert(0, msg);
      });
      // 滚动到底部
      _scrollToBottom();
      // 更新会话的lastMessage和lastReceiveTime
      _sessionStore.updateLastMessage(
        _sessionId,
        fileType.messageContent,
        msg.sendTime,
      );
    }
  }

  // 发送图片或视频消息(摄像头)
  void _sendMediaFromCamera(String mediaType) async {
    // 从摄像头拍摄图片或视频
    final picker = ImagePicker();
    XFile? media;
    if (mediaType == 'image') {
      media = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 240.w,
        maxHeight: 500.w,
      );
    } else if (mediaType == 'video') {
      media = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(minutes: 5),
      );
    }
    if (media != null) {
      // 文件路径
      final filePath = media.path;
      // 文件大小
      final fileSize = await media.length();
      // 文件名
      final filename = media.name;
      // 文件类型
      final fileType = _getFileType(filePath);
      // 校验文件大小
      if (!_validateFileSize(fileType, fileSize)) {
        return;
      }
      final multipart = await MultipartFile.fromFile(
        filePath,
        filename: filename,
      );
      // 发送消息
      final msg = await sendMessageApi(
        SendMsgReq(
          contactId: _contactId,
          contactType: _contactType,
          messageType: MessageTypeEnum.file.type,
          messageContent: fileType.messageContent,
          file: multipart,
        ),
      );
      setState(() {
        // 添加到发送后的消息到列表
        _msgList.insert(0, msg);
      });
      // 滚动到底部
      _scrollToBottom();
      // 更新会话的lastMessage和lastReceiveTime
      _sessionStore.updateLastMessage(
        _sessionId,
        fileType.messageContent,
        msg.sendTime,
      );
    }
  }

  // 发送个人名片
  Future<void> _sendPersonCard(PersonCardData contact) async {
    // 发送消息
    final msg = await sendMessageApi(
      SendMsgReq(
        contactId: _contactId,
        contactType: _contactType,
        messageType: MessageTypeEnum.personCard.type,
        messageContent: MessageTypeEnum.personCard.messageContent,
        data: jsonEncode(contact.toJson()),
      ),
    );
    setState(() {
      // 添加到发送后的消息到列表
      _msgList.insert(0, msg);
    });
    // 滚动到底部
    _scrollToBottom();
    // 更新会话的lastMessage和lastReceiveTime
    _sessionStore.updateLastMessage(
      _sessionId,
      MessageTypeEnum.personCard.messageContent,
      msg.sendTime,
    );
  }

  // 选择联系人
  void _selectContact() async {
    // 跳转到联系人选择页面选择联系人
    Navigator.push(
      context,
      RouteUtils.slideUp(
        (ctx) => ContactSelectPage(
          onSelect: (contact) async {
            final receiver = _userContactController.findUserContact(
              _contactId,
              _contactType,
            );
            if (receiver == null) {
              ToastUtils.showGlobalToast(msg: '联系人未找到');
              return false;
            }
            final contactData = PersonCardData(
              contactId: contact.contactId,
              contactType: contact.contactType,
              // 机器人等无原始名称的联系人回退到contactName(备注)
              contactName: contact.originName ?? contact.contactName,
            );
            final result = await showSendConfirmModal(
              context,
              receiver,
              contactData,
            );
            // 用户是否点击发送按钮
            final confirm = result != null && result;
            // 用户点击了确认发送
            if (confirm) {
              await _sendPersonCard(contactData);
            }
            return confirm;
          },
        ),
      ),
    );
  }

  // 发起视频通话
  void _makeVideoCall() async {
    // 发送消息
    final msg = await sendMessageApi(
      SendMsgReq(
        contactId: _contactId,
        contactType: _contactType,
        messageType: MessageTypeEnum.videoCall.type,
        messageContent: MessageTypeEnum.videoCall.messageContent,
      ),
    );
    setState(() {
      // 添加到发送后的消息到列表
      _msgList.insert(0, msg);
    });
    // 滚动到底部
    _scrollToBottom();
    // 更新会话的lastMessage和lastReceiveTime
    _sessionStore.updateLastMessage(
      _sessionId,
      MessageTypeEnum.videoCall.messageContent,
      msg.sendTime,
    );
    // 前往视频通话页面
    Navigator.pushNamed(
      context,
      RoutePath.videoCall,
      arguments: {
        'isCaller': true,
        'contactId': _contactId,
        'messageId': msg.messageId,
      },
    );
  }

  // 发起语音通话
  void _makeVoiceCall() async {
    // 发送消息
    final msg = await sendMessageApi(
      SendMsgReq(
        contactId: _contactId,
        contactType: _contactType,
        messageType: MessageTypeEnum.voiceCall.type,
        messageContent: MessageTypeEnum.voiceCall.messageContent,
      ),
    );
    setState(() {
      // 添加到发送后的消息到列表
      _msgList.insert(0, msg);
    });
    // 滚动到底部
    _scrollToBottom();
    // 更新会话的lastMessage和lastReceiveTime
    _sessionStore.updateLastMessage(
      _sessionId,
      MessageTypeEnum.voiceCall.messageContent,
      msg.sendTime,
    );
    // 前往视频通话页面
    Navigator.pushNamed(
      context,
      RoutePath.voiceCall,
      arguments: {
        'isCaller': true,
        'contactId': _contactId,
        'messageId': msg.messageId,
      },
    );
  }

  // 处理视频/语音通话事件
  void _onVideoOrVoiceCall(MessageTypeEnum messageType) {
    if (messageType == MessageTypeEnum.videoCall) {
      _makeVideoCall();
    } else if (messageType == MessageTypeEnum.voiceCall) {
      _makeVoiceCall();
    }
  }

  // 视频通话
  void _videoCall() {
    // 显示ActionSheet
    showMyBottomSheet(context, [
      SheetItem('视频通话', _makeVideoCall),
      SheetItem('语音通话', _makeVoiceCall),
    ]);
  }

  @override
  void initState() {
    super.initState();
    // 接收联系人id和联系人类型参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        _contactType = params['contactType'];
        _sessionId = params['sessionId'];
        _targetMessageId = params['targetMessageId'] as int?;
        // 设置当前活跃会话id
        setActiveSession(_sessionId);
        // 清空当前会话消息未读数量
        // 不能在build之前清空因为Obx在build之前重构会有问题，这里因为Future.microtask所以没有问题
        _messageStore.clearSessionUnreadCount(_sessionId);
        _getContactInfo();
        // 搜索跳转定位模式：从目标消息所在页加载并定位
        if (_targetMessageId != null && _targetMessageId! > 0) {
          _loadAroundMessage(_targetMessageId!);
        } else {
          _getMsgList().then((_) {
            _scrollToBottom();
          });
        }
        _msgListController.addListener(() {
          // 定位模式下滚动到最顶部（最新消息）时自动退出定位模式
          if (_isLocated && _msgListController.offset < 50.w) {
            setState(() => _isLocated = false);
          }
          // 当用户滚动到最旧的一条消息时才加载更多历史消息
          // reverse列表中 extentAfter=0 意味着已经滑到底部(最旧消息)
          if (_msgListController.position.extentAfter < 1) {
            _scrollDebouncer.run(_getMsgList);
          }
        });
      }
    });
    // 监听服务器推送消息事件
    _streamSubscription = eventBus.on<ServerMsgEvent>().listen((event) {
      // 群聊解散
      if (event.type == ServerMsgType.dissolveGroup) {
        final message = event.msg as ChatMessageRes;
        // 不是当前会话
        if (message.sessionId != _sessionId) {
          return;
        }
        setState(() {
          // 设置当前群聊状态为已解散
          _contactInfo?.groupStatus = GroupStatusEnum.dissolve;
          // 插入消息
          _msgList.insert(0, message);
        });
        _scrollToBottom();
        // 弹出提示
        showPromptDialog(context, '当前群聊已解散');
        return;
      }
      // 更新群聊信息
      if (event.type == ServerMsgType.updateGroup) {
        // 修改群聊名称
        setState(() {});
        return;
      }
      // 有消息撤回
      if (event.type == ServerMsgType.recallMessage) {
        final message = _msgList.firstWhereOrNull(
          (msg) => msg.messageId == event.msg.messageId,
        );
        if (message != null) {
          setState(() {
            message.status = MessageStatusEnum.recalled.status;
          });
        }
        return;
      }
      // 机器人输入中状态
      if (event.type == ServerMsgType.aiTyping) {
        final typingSessionId = (event.msg as Map<String, dynamic>)['sessionId'];
        if (typingSessionId != _sessionId) {
          return;
        }
        setState(() {
          _showTyping = true;
        });
        // 30秒超时自动隐藏(防御AI卡死)
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 30), () {
          if (!mounted) return;
          setState(() {
            _showTyping = false;
          });
        });
        return;
      }
      // 消息类型不是聊天消息，直接返回
      if (event.type != ServerMsgType.chat) {
        return;
      }
      // 消息内容
      final msg = event.msg as ChatMessageRes;
      // webrtc信令消息：通话挂断时更新本地通话消息的data（实时显示通话状态）
      if (msg.messageType == MessageTypeEnum.rtcSignal.type) {
        _updateCallMessageData(msg);
        return;
      }
      // 如果是当前用户发送的，也不处理
      if (msg.sendUserId != _userController.userInfo.value?.userId) {
        // 收到回复, 隐藏输入中气泡
        if (_showTyping) {
          _typingTimer?.cancel();
          setState(() {
            _showTyping = false;
          });
        }
        setState(() {
          _msgList.insert(0, msg);
        });
        // 如果滚动offset大于200，说明当前用户正在浏览历史消息，不应滚动到底部
        if (_msgListController.offset < 200.w) {
          _scrollToBottom();
        }
      }
    });
  }

  // 处理通话挂断信令，更新本地通话消息的data（通话状态/时长）
  void _updateCallMessageData(ChatMessageRes msg) {
    // 只处理挂断信令
    final signal = jsonDecode(msg.messageContent);
    if (signal['type'] != RTCSignalEnum.callEnd) {
      return;
    }
    // 信令数据中的通话消息id
    final messageId = signal['data']?['messageId'];
    if (messageId == null) {
      return;
    }
    // 在本地消息列表中找到对应的通话消息并更新data
    final index = _msgList.indexWhere((m) => m.messageId == messageId);
    if (index == -1) {
      return;
    }
    setState(() {
      _msgList[index].data = msg.data;
    });
  }

  // 获取消息列表
  Future<void> _getMsgList({bool clear = false, int? page}) async {
    // 如果正在请求或者没有更多数据了
    if (_isLoading || !_hasMore) {
      return;
    }
    _isLoading = true;
    try {
      // 清空模式（定位加载）：重置最大消息id
      if (clear) {
        _msgList.clear();
        _maxMessageId = null;
      }
      // 如果已经存在消息
      if (_msgList.isNotEmpty) {
        _maxMessageId = _msgList[_msgList.length - 1].messageId;
      }
      final res = await getMessageListApi(
        GetMsgListReq(
          page: page ?? _page,
          pageSize: _pageSize,
          contactId: _contactId,
          maxMessageId: _maxMessageId,
        ),
      );
      final list = res.list.map((msg) => ChatMessageRes.fromJson(msg)).toList();
      if (list.isEmpty) {
        _hasMore = false;
        return;
      }
      // 根据messageId从大到小排序
      list.sort((a, b) => b.messageId - a.messageId);
      _msgList = [..._msgList, ...list];
      setState(() {});
    } catch (e) {
      // 请求失败（request.dart已弹出错误提示），打印日志便于排查
      print('加载消息列表失败: $e');
    } finally {
      // 无论成功失败都复位加载状态，避免卡死导致后续加载被跳过
      _isLoading = false;
    }
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

  // 删除好友/群聊
  void _delContact() async {
    await delContactApi(_contactId, _contactType);
    ToastUtils.showGlobalToast(msg: '删除成功');
    // 删除联系人和会话
    _userContactController.del(_contactId, _contactType);
    _sessionStore.delSession(_contactId);
    Navigator.pop(context);
  }

  // 滚动到底部
  void _scrollToBottom() {
    // 等待当前帧绘制完成后再滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _msgListController.jumpTo(0);
    });
  }

  // 获取消息GlobalKey（用于定位滚动）
  GlobalKey _messageKey(int messageId) {
    return _messageKeys.putIfAbsent(messageId, () => GlobalKey());
  }

  // 定位到指定消息（从目标消息所在页开始加载）
  Future<void> _loadAroundMessage(int targetMessageId) async {
    setState(() => _isLocated = true);
    try {
      // 目标消息所在页码（按消息id倒序分页）
      var pageNum = await getMsgPageNumApi(targetMessageId, _pageSize);
      // 从目标页加载，如果目标消息不在该页则向前翻页查找（防止期间有新消息导致页码偏移）
      while (true) {
        await _getMsgList(clear: true, page: pageNum);
        if (_msgList.any((m) => m.messageId == targetMessageId)) {
          break;
        }
        if (pageNum <= 1 || !_hasMore) {
          break;
        }
        pageNum--;
      }
      // 滚动定位到目标消息
      final index = _msgList.indexWhere((m) => m.messageId == targetMessageId);
      if (index != -1) {
        setState(() => _highlightMessageId = targetMessageId);
        _scrollToMessage(index);
        // 1.5秒后取消高亮
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _highlightMessageId = null);
          }
        });
      }
    } catch (e) {
      // 定位失败（如页码接口异常），回退到加载最新消息
      print('定位消息失败: $e');
      setState(() => _isLocated = false);
      _maxMessageId = null;
      await _getMsgList();
      _scrollToBottom();
    }
  }

  // 滚动到指定消息（粗跳估算位置后精确滚动）
  void _scrollToMessage(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 先粗跳估算位置，确保目标消息被构建
      final estimatedOffset = index * 80.w;
      final maxOffset = _msgListController.position.maxScrollExtent;
      _msgListController.jumpTo(
        estimatedOffset > maxOffset ? maxOffset : estimatedOffset,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetKey = _messageKeys[_targetMessageId];
        final targetContext = targetKey?.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.3,
          );
        }
      });
    });
  }

  // 回到最新消息（退出定位模式）
  void _backToLatest() async {
    setState(() {
      _isLocated = false;
      _highlightMessageId = null;
      // 强制复位，防止定位加载未完成时点击导致跳过加载
      _isLoading = false;
    });
    _maxMessageId = null;
    await _getMsgList(clear: true);
    _scrollToBottom();
  }

  // 构建回到最新悬浮条（定位模式下显示）
  Widget _buildBackToLatest() {
    if (!_isLocated) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Center(
        child: GestureDetector(
          onTap: _backToLatest,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '回到最新消息',
              style: TextStyle(fontSize: 13.sp, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  // 发送文本消息
  void _sendText() async {
    // 如果消息为空
    if (_msg.isBlank == true) {
      ToastUtils.showGlobalToast(msg: '消息不能为空');
      return;
    }
    // 发送消息
    final msg = await sendMessageApi(
      SendMsgReq(
        contactId: _contactId,
        contactType: _contactType,
        messageType: MessageTypeEnum.text.type,
        messageContent: _msg,
      ),
    );
    setState(() {
      // 添加到发送后的消息到列表
      _msgList.insert(0, msg);
    });
    // 清空输入框(controller与notifier各自触发局部刷新, 无需重建整个页面)
    _messageController.clear();
    _msg = '';
    // 滚动到底部
    _scrollToBottom();
    // 更新会话的lastMessage和lastReceiveTime
    _sessionStore.updateLastMessage(
      _sessionId,
      msg.messageContent,
      msg.sendTime,
    );
  }

  // 转发消息
  void _shareMessage(ChatMessageRes message, UserContactRes contact) async {
    final msg = await shareMessageApi(
      ShareMsgReq(
        messageId: message.messageId,
        contactId: contact.contactId,
        contactType: contact.contactType,
      ),
    );
    // 如果是当前会话的消息，就执行和其他方法一样的操作
    if (msg.sessionId == _sessionId) {
      setState(() {
        // 添加到发送后的消息到列表
        _msgList.insert(0, msg);
        // 滚动到底部
        _scrollToBottom();
      });
    }
    // 更新会话的lastMessage和lastReceiveTime
    _sessionStore.updateLastMessage(
      msg.sessionId,
      msg.messageContent,
      msg.sendTime,
    );
    ToastUtils.showGlobalToast(msg: '发送成功');
  }

  // 进入多选模式(并选中当前消息)
  void _enterMultiSelect(int messageId) {
    // 录音中先取消(多指操作进入多选的兜底)
    if (_isRecording) {
      unawaited(_finishRecord(canceled: true));
    }
    setState(() {
      _multiSelect = true;
      _selectedIds.add(messageId);
      // 复位输入面板
      _showEmotion = false;
      _showMore = false;
      _showVoice = false;
    });
  }

  // 退出多选模式
  void _exitMultiSelect() {
    setState(() {
      _multiSelect = false;
      _selectedIds.clear();
      // 复位输入面板
      _showEmotion = false;
      _showMore = false;
      _showVoice = false;
    });
  }

  // 勾选/取消勾选消息
  void _toggleSelect(int messageId) {
    if (!_multiSelect) {
      return;
    }
    if (_selectedIds.contains(messageId)) {
      setState(() {
        _selectedIds.remove(messageId);
      });
      return;
    }
    if (_selectedIds.length >= 100) {
      ToastUtils.showGlobalToast(msg: '最多只能选择100条消息');
      return;
    }
    setState(() {
      _selectedIds.add(messageId);
    });
  }

  // 构建聊天记录快照(按时间升序)
  List<Map<String, dynamic>> _buildSnapshot() {
    final selected = _msgList
        .where((m) =>
            _selectedIds.contains(m.messageId) &&
            m.status == MessageStatusEnum.sent.status)
        .toList()
      ..sort((a, b) {
        // 时间相同按消息id稳定排序
        final timeCmp = a.sendTime.compareTo(b.sendTime);
        return timeCmp != 0 ? timeCmp : a.messageId.compareTo(b.messageId);
      });
    return List.generate(selected.length, (index) {
      final m = selected[index];
      return {
        'messageType': m.messageType,
        'messageContent': m.messageContent,
        'sendUserId': m.sendUserId,
        'sendUserNickname': m.sendUserNickname,
        'sendTime': m.sendTime,
        'fileId': m.fileId,
        'fileName': m.fileName,
        'fileType': m.fileType,
        'fileSize': m.fileSize,
        'data': m.data,
      };
    });
  }

  // 合并转发聊天记录
  void _mergeForward() async {
    if (_selectedIds.isEmpty) {
      ToastUtils.showGlobalToast(msg: '请选择要转发的消息');
      return;
    }
    // 上一次转发尚未结束(防重复)
    if (_isForwarding) {
      return;
    }
    // 构建快照(过滤已撤回, 按时间升序)
    final messages = _buildSnapshot();
    final count = messages.length;
    final snapshot = jsonEncode({'messages': messages});
    // 选择页打开期间也视为转发中, 防止重复push
    _isForwarding = true;
    try {
      await Navigator.push(
        context,
        RouteUtils.slideUp(
          (ctx) => ContactSelectPage(
            onSelect: (contact) async {
              final res = await showPromptDialog(
                context,
                '是否确定向${contact.contactName}转发$count条聊天记录?',
                showCancel: true,
              );
              // 用户取消转发
              if (res == null || !res) {
                return false;
              }
              try {
                final msg = await sendMessageApi(
                  SendMsgReq(
                    contactId: contact.contactId,
                    contactType: contact.contactType,
                    messageType: MessageTypeEnum.chatRecord.type,
                    messageContent: '[$count条聊天记录]',
                    data: snapshot,
                  ),
                );
                if (!mounted) {
                  return false;
                }
                // 如果是当前会话的消息，插入列表并滚动到底部
                if (msg.sessionId == _sessionId) {
                  setState(() {
                    _msgList.insert(0, msg);
                  });
                  _scrollToBottom();
                }
                // 更新会话的lastMessage和lastReceiveTime
                _sessionStore.updateLastMessage(
                  msg.sessionId,
                  msg.messageContent,
                  msg.sendTime,
                );
                ToastUtils.showGlobalToast(msg: '发送成功');
                _exitMultiSelect();
                return true;
              } catch (_) {
                ToastUtils.showGlobalToast(msg: '发送失败');
                return false;
              }
            },
          ),
          settings: RouteSettings(arguments: {'searchAll': true}),
        ),
      );
    } finally {
      _isForwarding = false;
    }
  }

  // 多选模式顶部栏(取消+已选数量)
  Widget _buildMultiSelectHeader() {
    return Container(
      height: 50.w,
      decoration: const BoxDecoration(color: Color.fromRGBO(237, 237, 237, 1)),
      child: Row(
        children: [
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _exitMultiSelect,
            child: Text(
              '取消',
              style: TextStyle(color: Colors.black, fontSize: 16.sp),
            ),
          ),
          SizedBox(width: 15.w),
          Text(
            '已选 ${_selectedIds.length} 项',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17.sp,
              fontWeight: .bold,
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  // 多选模式底部工具栏(合并转发)
  Widget _buildMergeForwardBar() {
    final count = _selectedIds.length;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.w),
      color: const Color.fromRGBO(247, 247, 247, 1),
      child: Center(
        child: GestureDetector(
          onTap: count == 0 ? null : _mergeForward,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.w),
            decoration: BoxDecoration(
              color: count == 0
                  ? const Color.fromRGBO(170, 170, 170, 1)
                  : const Color.fromRGBO(20, 134, 237, 1),
              borderRadius: .circular(6.r),
            ),
            child: Text(
              '合并转发($count)',
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
          ),
        ),
      ),
    );
  }

  // 消息列表
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _msgListController,
      itemCount: _msgList.length + (_showTyping ? 1 : 0),
      padding: EdgeInsets.only(top: 10.w),
      reverse: true,
      itemBuilder: (ctx, index) {
        // 机器人输入中气泡(列表最底部, 独立图层避免动画重绘整个消息列表)
        if (_showTyping && index == 0) {
          return RepaintBoundary(child: _buildTypingBubble());
        }
        // 有输入中气泡时, 真实消息下标偏移1
        final realIndex = index - (_showTyping ? 1 : 0);
        // 构建单条消息（带定位key，定位后高亮显示）
        Widget buildMsg() {
          final message = _msgList[realIndex];
          // 多选模式下该消息是否可勾选
          final selectable =
              message.status == MessageStatusEnum.sent.status &&
              message.messageType != MessageTypeEnum.systemNotice.type &&
              message.messageType != MessageTypeEnum.rtcSignal.type;
          Widget msg = ChatMessage(
            message: message,
            scrollController: _msgListController,
            onShareMessage: _shareMessage,
            onVideoOrVoiceCall: _onVideoOrVoiceCall,
            multiSelectMode: _multiSelect,
            selected: _selectedIds.contains(message.messageId),
            onSelectTap: selectable
                ? () => _toggleSelect(message.messageId)
                : null,
            onMultiSelect: () => _enterMultiSelect(message.messageId),
          );
          // 定位后高亮目标消息
          if (message.messageId == _highlightMessageId) {
            msg = Container(
              color: const Color.fromRGBO(255, 236, 179, 0.5),
              child: msg,
            );
          }
          // RepaintBoundary缓存消息图层: 键盘动画/滚动/输入中气泡动画时
          // 未变化的消息直接复用图层, 避免整列表重新光栅化
          return RepaintBoundary(
            key: _messageKey(message.messageId),
            child: msg,
          );
        }

        // 第一条消息显示发送时间，因为顺序翻转，所以_msgList.length-1是第一条消息
        // 两条消息发送时间间隔超过5分钟就显示时间
        if (realIndex == _msgList.length - 1 ||
            (_msgList[realIndex].sendTime - _msgList[realIndex + 1].sendTime) >
                5 * 60 * 1000) {
          return Column(
            spacing: 10.w,
            children: [
              Text(
                formatTimestamp(_msgList[realIndex].sendTime),
                textAlign: .center,
                style: TextStyle(
                  color: const Color.fromRGBO(123, 123, 128, 1),
                  fontSize: 14.sp,
                ),
              ),
              buildMsg(),
            ],
          );
        }
        return buildMsg();
      },
    );
  }

  // 机器人输入中气泡
  Widget _buildTypingBubble() {
    return Padding(
      padding: EdgeInsets.only(left: 15.w, bottom: 10.w),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            '对方正在输入…',
            style: TextStyle(color: Colors.black54, fontSize: 14.sp),
          ),
        ),
      ),
    );
  }

  // 语音录入区域(按住说话)
  Widget _buildVoice() {
    return GestureDetector(
      // 长按开始录音
      onLongPressStart: (details) {
        _pressStartDy = details.globalPosition.dy;
        // 标记手指仍按在按钮上
        _pressActive = true;
        _startRecord();
      },
      // 上滑超过一定距离进入取消发送状态
      onLongPressMoveUpdate: (details) {
        final canceled = details.globalPosition.dy < _pressStartDy - 80.w;
        if (canceled != _recordCanceled) {
          setState(() {
            _recordCanceled = canceled;
          });
        }
      },
      onLongPressEnd: (details) {
        // 手指已松开
        _pressActive = false;
        _finishRecord();
      },
      // 手势被中断(如页面切换)视为取消
      onLongPressCancel: () {
        // 手指已松开(手势被中断)
        _pressActive = false;
        _finishRecord(canceled: true);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: _isRecording
              ? const Color.fromRGBO(237, 237, 237, 1)
              : Colors.white,
        ),
        padding: EdgeInsets.all(6.w),
        alignment: Alignment.center,
        child: Text(
          _isRecording ? '松开 结束' : '按住 说话',
          style: TextStyle(color: Colors.black, fontSize: 16.sp),
        ),
      ),
    );
  }

  // 开始录音
  Future<void> _startRecord() async {
    // 正在录音时不允许再次启动
    if (_isRecording) {
      return;
    }
    // 请求麦克风权限
    final status = await Permission.microphone.request();
    // 拒绝或永久拒绝
    if (status.isDenied) {
      ToastUtils.showGlobalToast(msg: '没有麦克风权限');
      return;
    }
    // 永久拒绝，引导去设置页开启
    if (status.isPermanentlyDenied) {
      ToastUtils.showGlobalToast(msg: '请在设置中开启麦克风权限');
      openAppSettings();
      return;
    }
    if (!mounted) return;
    // 停止正在播放的语音，避免录音时拾取扬声器回声
    await VoicePlayer.instance.stop();
    // 录音文件保存路径
    final dir = await getTemporaryDirectory();
    _recordPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    // 开始录音
    try {
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          bitRate: 64000,
        ),
        path: _recordPath,
      );
    } catch (_) {
      // 启动录音失败
      ToastUtils.showGlobalToast(msg: '录音失败');
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordCanceled = false;
      });
      return;
    }
    if (!mounted) return;
    // 手指已松开(如系统权限弹窗中断手势)，取消刚启动的录音
    if (!_pressActive) {
      // 取消刚启动的录音(忽略取消失败)
      try {
        await _audioRecorder.cancel();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordCanceled = false;
      });
      return;
    }
    setState(() {
      _isRecording = true;
      _recordCanceled = false;
      _recordDuration = 0;
      _recordFinished = false;
    });
    // 计时器(每秒+1)
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordDuration++;
      });
      // 达到60秒上限自动停止并发送
      if (_recordDuration >= 60) {
        _finishRecord();
      }
    });
  }

  // 结束录音
  Future<void> _finishRecord({bool canceled = false}) async {
    if (!_isRecording || _recordFinished) {
      return;
    }
    _recordFinished = true;
    // 停止计时器
    _recordTimer?.cancel();
    _recordTimer = null;
    final path = _recordPath;
    // 上滑取消或手势中断
    if (canceled || _recordCanceled) {
      // 取消录音(忽略取消失败)
      try {
        await _audioRecorder.cancel();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordCanceled = false;
      });
      return;
    }
    // 停止录音
    try {
      await _audioRecorder.stop();
    } catch (_) {
      // 停止录音失败，删除临时文件
      try {
        await File(path).delete();
      } catch (_) {}
      ToastUtils.showGlobalToast(msg: '录音失败');
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordCanceled = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordCanceled = false;
    });
    // 说话时间太短
    if (_recordDuration < 1) {
      // 删除录音文件
      try {
        await File(path).delete();
      } catch (_) {}
      ToastUtils.showGlobalToast(msg: '说话时间太短');
      return;
    }
    await _sendVoice(path, _recordDuration);
  }

  // 发送语音消息
  Future<void> _sendVoice(String path, int duration) async {
    // 封装multipart
    final file = await MultipartFile.fromFile(path);
    try {
      // 发送消息
      final msg = await sendMessageApi(
        SendMsgReq(
          contactId: _contactId,
          contactType: _contactType,
          messageType: MessageTypeEnum.voice.type,
          messageContent: MessageTypeEnum.voice.messageContent,
          data: jsonEncode({'duration': duration}),
          file: file,
        ),
      );
      if (!mounted) return;
      setState(() {
        // 添加到发送后的消息到列表
        _msgList.insert(0, msg);
      });
      // 滚动到底部
      _scrollToBottom();
      // 更新会话的lastMessage和lastReceiveTime
      _sessionStore.updateLastMessage(
        _sessionId,
        MessageTypeEnum.voice.messageContent,
        msg.sendTime,
      );
    } catch (_) {
      ToastUtils.showGlobalToast(msg: '语音发送失败');
    } finally {
      // 删除临时录音文件
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  // 录音面板(悬浮在输入栏上方)
  Widget _buildRecordPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 70.w,
      child: Center(
        child: Container(
          width: 170.w,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.w),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(60, 60, 60, 0.9),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8.w,
            children: [
              Icon(
                _recordCanceled ? Icons.close_rounded : MyIcon.voice,
                size: 30.w,
                color: _recordCanceled
                    ? const Color.fromRGBO(241, 90, 81, 1)
                    : Colors.white,
              ),
              Text(
                formatDuration(_recordDuration * 1000),
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _recordCanceled ? '松开手指，取消发送' : '松开发送，上滑取消',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _recordCanceled
                      ? const Color.fromRGBO(241, 90, 81, 1)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 输入框
  Widget _buildInput() {
    return TextField(
      controller: _messageController,
      focusNode: _messageFocusNode,
      onChanged: (value) {
        // 只更新ValueNotifier触发输入行局部重建, 不重建整个页面
        _msg = value;
      },
      onSubmitted: (value) {
        _sendText();
      },
      onTap: () {
        setState(() {
          _showVoice = false;
          _showMore = false;
          _showEmotion = false;
        });
      },
      textInputAction: TextInputAction.send,
      maxLength: 300,
      maxLines: 3,
      minLines: 1,
      // 隐藏计数文本
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => const SizedBox.shrink(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.all(6.w),
        isDense: true,
      ),
    );
  }

  // 发送按钮
  Widget _buildSendBtn() {
    return GestureDetector(
      onTap: () {
        _sendText();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5.w, horizontal: 12.w),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 134, 237, 1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          '发送',
          style: TextStyle(fontSize: 15.sp, color: Colors.white),
        ),
      ),
    );
  }

  // emoji表情区域
  Widget _buildEmoji() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 200.w,
          child: GridView.builder(
            // 面板切换后保留滚动位置
            key: const PageStorageKey('emoji_grid'),
            itemCount: unicodeEmojis.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 5.w,
              mainAxisSpacing: 5.w,
            ),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                _messageController.text += unicodeEmojis[index];
                // 程序修改controller不会触发onChanged, 需手动同步notifier
                _msg = _messageController.text;
              },
              child: Text(
                unicodeEmojis[index],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
        ),
        // 删除最后一个字符图标
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: GestureDetector(
              onTap: () {
                // 消息为空
                if (_msg.isEmpty) {
                  return;
                }
                // 删除最后一个字符
                _messageController.text = _messageController.text.characters
                    .skipLast(1)
                    .toString();
                _msg = _messageController.text;
              },
              child: Icon(
                MyIcon.backspace,
                color: _msg.isNotEmpty
                    ? Colors.black
                    : const Color.fromRGBO(237, 237, 237, 1),
                size: 25.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建更多功能项
  Widget _buildMoreItem(MoreItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        spacing: 5.w,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, size: 25.w, color: Colors.black),
          ),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color.fromRGBO(144, 144, 144, 1),
            ),
          ),
        ],
      ),
    );
  }

  // 更多区域
  Widget _buildMore() {
    // 更多功能列表
    final moreItems = [
      MoreItem(
        name: '图片',
        icon: MyIcon.gallery,
        onTap: () {
          _sendMediaFromGallery('image');
        },
      ),
      MoreItem(
        name: '视频',
        icon: MyIcon.video,
        onTap: () {
          _sendMediaFromGallery('video');
        },
      ),
      MoreItem(
        name: '拍照',
        icon: MyIcon.camera,
        onTap: () {
          _sendMediaFromCamera('image');
        },
      ),
      MoreItem(
        name: '录像',
        icon: MyIcon.camera,
        onTap: () {
          _sendMediaFromCamera('video');
        },
      ),
      // 机器人不能通话，隐藏通话入口
      if (_contactType == UserContactTypeEnum.user &&
          _contactId != GlobalConstants.robotContactId)
        MoreItem(name: '视频通话', icon: MyIcon.video, onTap: _videoCall),
      MoreItem(name: '个人名片', icon: MyIcon.personCard, onTap: _selectContact),
      MoreItem(name: '文件', icon: MyIcon.file, onTap: _sendFile),
    ];

    return SizedBox(
      width: double.infinity,
      height: 200.w,
      child: Center(
        child: GridView.count(
          // 让GridView根据内容调整高度
          physics: const NeverScrollableScrollPhysics(),
          // 禁止滚动
          crossAxisCount: 4,
          mainAxisSpacing: 10.w,
          children: List.generate(
            moreItems.length,
            (index) => _buildMoreItem(moreItems[index]),
          ),
        ),
      ),
    );
  }

  // 键盘图标
  Widget _buildKeyboardIcon() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showVoice = false;
          _showMore = false;
          _showEmotion = false;
        });
        // 等待当前帧绘制完成后再请求焦点
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_messageFocusNode);
          // 主动显示软键盘
          SystemChannels.textInput.invokeMethod('TextInput.show');
        });
      },
      child: Icon(MyIcon.keyboard, size: 30.w),
    );
  }

  // 底部操作区域
  Widget _buildBottom() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      color: const Color.fromRGBO(247, 247, 247, 1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _msgNotifier,
            // 输入框作为child缓存: 每次按键只重建按钮行, 输入框由controller自行驱动刷新
            child: _showVoice ? _buildVoice() : _buildInput(),
            builder: (context, msg, child) {
              return Column(
                children: [
                  Row(
                    spacing: 6.w,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 录音时屏蔽语音切换按钮(不影响按住说话手势)
                      AbsorbPointer(
                        absorbing: _isRecording,
                        child: _showVoice
                            ? _buildKeyboardIcon()
                            : GestureDetector(
                                onTap: () {
                                  // 使得输入框失去焦点
                                  FocusScope.of(context).unfocus();
                                  SystemChannels.textInput.invokeMethod(
                                    'TextInput.hide',
                                  );
                                  setState(() {
                                    _showVoice = true;
                                    _showMore = false;
                                    _showEmotion = false;
                                  });
                                },
                                child: Icon(MyIcon.voice, size: 30.w),
                              ),
                      ),
                      Expanded(child: child!),
                      // 录音时屏蔽表情按钮
                      AbsorbPointer(
                        absorbing: _isRecording,
                        child: _showEmotion
                            ? _buildKeyboardIcon()
                            : GestureDetector(
                                onTap: () {
                                  // 隐藏软键盘
                                  SystemChannels.textInput.invokeMethod(
                                    'TextInput.hide',
                                  );
                                  setState(() {
                                    _showVoice = false;
                                    _showMore = false;
                                    _showEmotion = true;
                                  });
                                },
                                child: Icon(MyIcon.emotion, size: 30.w),
                              ),
                      ),
                      // 录音时屏蔽加号/发送按钮
                      AbsorbPointer(
                        absorbing: _isRecording,
                        child: msg.isEmpty
                            ? (_showMore
                                  ? _buildKeyboardIcon()
                                  : GestureDetector(
                                      onTap: () {
                                        // 输入框失去焦点
                                        FocusScope.of(context).unfocus();
                                        setState(() {
                                          _showVoice = false;
                                          _showMore = true;
                                          _showEmotion = false;
                                        });
                                      },
                                      child: Icon(
                                        MyIcon.messageAdd,
                                        size: 30.w,
                                      ),
                                    ))
                            : _buildSendBtn(),
                      ),
                    ],
                  ),
                  if (_showEmotion || _showMore) SizedBox(height: 10.w),
                  // emoji
                  if (_showEmotion) _buildEmoji(),
                  // 更多
                  if (_showMore) _buildMore(),
                ],
              );
            },
          ),
          // 录音面板
          if (_isRecording) _buildRecordPanel(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 拦截所有返回上一页，自定义处理
      onPopInvokedWithResult: (didPop, _) {
        // 如果已经返回，则无需处理
        if (didPop) {
          return;
        }
        // 多选模式优先退出多选
        if (_multiSelect) {
          _exitMultiSelect();
          return;
        }
        // 如果当前输入框还持有焦点，失去焦点，如果没有，返回上一页
        if (_messageFocusNode.hasFocus) {
          FocusScope.of(context).unfocus();
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
          foregroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: const Color.fromRGBO(237, 237, 237, 1),
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: const Color.fromRGBO(247, 247, 247, 1),
            // 底部导航栏背景
            systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
          ),
        ),
        backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
        body: SafeArea(
          child: Column(
            children: [
              // 多选模式: 显示取消+已选数量, 否则显示导航栏
              if (_multiSelect)
                _buildMultiSelectHeader()
              else
                PageHeader(
                  title: _contactType == UserContactTypeEnum.user
                      ? _contactName
                      : '$_contactName(${_contactInfo?.memberCount})',
                  showLeftBackIcon: true,
                  backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
                  rightIconList: [
                    GestureDetector(
                      onTap: () async {
                        // 如果双方是好友关系，跳转到联系人信息
                        if (_contactType == UserContactTypeEnum.user) {
                          Navigator.pushNamed(
                            context,
                            RoutePath.contactInfo,
                            arguments: {'contactId': _contactId},
                          );
                        } else if (_contactType == UserContactTypeEnum.group) {
                          // 如果是群聊，跳转到群聊设置页面
                          // 群聊已解散，询问是否要删除该群聊
                          if (_contactInfo?.groupStatus ==
                              GroupStatusEnum.dissolve) {
                            showPromptDialog(
                              context,
                              showCancel: true,
                              '是否要删除该群聊',
                              onConfirm: _delContact,
                            );
                            return;
                          }
                          final contactStatus = await Navigator.pushNamed(
                            context,
                            RoutePath.groupSetting,
                            arguments: {'groupId': _contactInfo?.contactId},
                          );
                          // 群聊已解散/已退出群聊
                          if (UserContactStatusEnum.delete == contactStatus) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 25.w,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              Expanded(
                child: Stack(
                  // 非定位子项强制填充，否则Stack宽度会被收缩为0
                  fit: StackFit.expand,
                  children: [
                    _buildMessageList(),
                    if (!_multiSelect) _buildBackToLatest(),
                  ],
                ),
              ),
              if (_contactInfo?.groupStatus != GroupStatusEnum.dissolve)
                _multiSelect ? _buildMergeForwardBar() : _buildBottom(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 删除活跃会话id
    removeActiveSession();
    // 取消监听
    _streamSubscription.cancel();
    // 取消输入中气泡定时器
    _typingTimer?.cancel();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _msgNotifier.dispose();
    // 销毁ScrollController
    _msgListController.dispose();
    _scrollDebouncer.dispose();
    // 停止录音(防止页面销毁后录音残留)
    _recordTimer?.cancel();
    if (_isRecording) {
      _audioRecorder.cancel();
    }
    _audioRecorder.dispose();
    // 删除残留的临时录音文件
    if (_recordPath.isNotEmpty) {
      final path = _recordPath;
      _recordPath = '';
      final file = File(path);
      // 异步删除，忽略删除失败
      unawaited(file.delete().catchError((_) => file));
    }
    super.dispose();
  }
}

// 更多功能项
class MoreItem {
  final String name;
  final IconData icon;
  final void Function() onTap;

  MoreItem({required this.name, required this.icon, required this.onTap});
}
