import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/animation.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/emoji.dart';
import 'package:zchat/common/event_bus.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/utils.dart';
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

  // 文本消息
  String _msg = '';

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
              contactName: contact.originName,
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
      // 清空输入框
      _messageController.clear();
      _msg = '';
    });
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

  // 消息列表
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _msgListController,
      itemCount: _msgList.length,
      padding: EdgeInsets.only(top: 10.w),
      reverse: true,
      itemBuilder: (ctx, index) {
        // 构建单条消息（带定位key，定位后高亮显示）
        Widget buildMsg() {
          final message = _msgList[index];
          Widget msg = ChatMessage(
            message: message,
            scrollController: _msgListController,
            onShareMessage: _shareMessage,
            onVideoOrVoiceCall: _onVideoOrVoiceCall,
          );
          // 定位后高亮目标消息
          if (message.messageId == _highlightMessageId) {
            msg = Container(
              color: const Color.fromRGBO(255, 236, 179, 0.5),
              child: msg,
            );
          }
          return Container(key: _messageKey(message.messageId), child: msg);
        }

        // 第一条消息显示发送时间，因为顺序翻转，所以_msgList.length-1是第一条消息
        // 两条消息发送时间间隔超过5分钟就显示时间
        if (index == _msgList.length - 1 ||
            (_msgList[index].sendTime - _msgList[index + 1].sendTime) >
                5 * 60 * 1000) {
          return Column(
            spacing: 10.w,
            children: [
              Text(
                formatTimestamp(_msgList[index].sendTime),
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

  // 语音录入区域
  Widget _buildVoice() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.white,
      ),
      padding: EdgeInsets.all(6.w),
      alignment: Alignment.center,
      child: Text(
        '按住 说话',
        style: TextStyle(color: Colors.black, fontSize: 16.sp),
      ),
    );
  }

  // 输入框
  Widget _buildInput() {
    return TextField(
      controller: _messageController,
      focusNode: _messageFocusNode,
      onChanged: (value) {
        setState(() {
          _msg = value;
        });
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
            itemCount: unicodeEmojis.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 5.w,
              mainAxisSpacing: 5.w,
            ),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                setState(() {
                  _messageController.text += unicodeEmojis[index];
                  _msg += unicodeEmojis[index];
                });
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
                setState(() {
                  _messageController.text = _messageController.text.characters
                      .skipLast(1)
                      .toString();
                  _msg = _msg.characters.skipLast(1).toString();
                });
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
      if (_contactType == UserContactTypeEnum.user)
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
      child: Column(
        children: [
          Row(
            spacing: 6.w,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _showVoice
                  ? _buildKeyboardIcon()
                  : GestureDetector(
                      onTap: () {
                        // 使得输入框失去焦点
                        FocusScope.of(context).unfocus();
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        setState(() {
                          _showVoice = true;
                          _showMore = false;
                          _showEmotion = false;
                        });
                      },
                      child: Icon(MyIcon.voice, size: 30.w),
                    ),
              Expanded(child: _showVoice ? _buildVoice() : _buildInput()),
              _showEmotion
                  ? _buildKeyboardIcon()
                  : GestureDetector(
                      onTap: () {
                        // 隐藏软键盘
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        setState(() {
                          _showVoice = false;
                          _showMore = false;
                          _showEmotion = true;
                        });
                      },
                      child: Icon(MyIcon.emotion, size: 30.w),
                    ),
              _msg.isEmpty
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
                            child: Icon(MyIcon.messageAdd, size: 30.w),
                          ))
                  : _buildSendBtn(),
            ],
          ),
          if (_showEmotion || _showMore) SizedBox(height: 10.w),
          // emoji
          Offstage(offstage: !_showEmotion, child: _buildEmoji()),
          // 更多
          Offstage(offstage: !_showMore, child: _buildMore()),
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
              // 导航栏
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
                  children: [_buildMessageList(), _buildBackToLatest()],
                ),
              ),
              if (_contactInfo?.groupStatus != GroupStatusEnum.dissolve)
                _buildBottom(),
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
    _messageController.dispose();
    _messageFocusNode.dispose();
    // 销毁ScrollController
    _msgListController.dispose();
    _scrollDebouncer.dispose();
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
