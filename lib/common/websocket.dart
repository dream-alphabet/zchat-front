import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/event_bus.dart';
import 'package:zchat/common/message.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/server_msg.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/message.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/token.dart';
import 'package:zchat/stores/user.dart';

/// WebSocket状态
enum SocketStatus {
  socketStatusConnecting, // 连接中
  socketStatusConnected, // 已连接
  socketStatusFailed, // 失败
  socketStatusClosed, // 连接关闭
}

// websocket连接地址
const websocketUrl = GlobalConstants.wsUrl;

class WebSocketUtility {
  /// 单例对象
  static final WebSocketUtility _socket = WebSocketUtility._internal();

  /// 内部构造方法
  WebSocketUtility._internal();

  /// 获取单例
  factory WebSocketUtility() {
    return _socket;
  }

  WebSocketChannel? _webSocket; // WebSocket
  SocketStatus _socketStatus = SocketStatus.socketStatusClosed;
  Timer? _heartBeat; // 心跳定时器
  final int _heartInterval = 5 * 1000; // 心跳间隔
  int _reconnectTimes = 0; // 当前重连次数
  final int _reconnectInterval = 3000; // 重连间隔3秒
  Timer? _reconnectTimer; // 重连定时器

  Function? _onError; // 改为可空，避免late初始化问题
  Function? _onOpen;
  void Function(dynamic)? _onMessage;

  /// 初始化WebSocket
  void initWebSocket({
    required Function onOpen,
    required void Function(dynamic) onMessage,
    required Function onError,
  }) {
    _onOpen = onOpen;
    _onMessage = onMessage;
    _onError = onError;
    openSocket();
  }

  /// 开启WebSocket连接
  void openSocket() {
    final token = tokenManager.getToken();
    if (token.isEmpty) {
      return;
    }

    // 如果已有连接，先关闭
    closeSocket();

    _socketStatus = SocketStatus.socketStatusConnecting;

    final url = '$websocketUrl?token=$token';

    try {
      _webSocket = WebSocketChannel.connect(Uri.parse(url));

      // 监听连接就绪
      _webSocket!.ready
          .then((_) {
            _socketStatus = SocketStatus.socketStatusConnected;
            _reconnectTimes = 0; // 重置重连计数

            // 取消重连定时器
            _reconnectTimer?.cancel();
            _reconnectTimer = null;

            // 执行开启回调
            _onOpen?.call();

            // 启动心跳
            initHeartBeat();

            // 监听消息（放到这里确保连接成功后才开始监听）
            _webSocket!.stream.listen(
              (data) {
                _onMessage?.call(data);
              },
              onError: (error) {
                webSocketOnError(error);
              },
              onDone: webSocketOnDone,
            );
          })
          .catchError((error) {
            webSocketOnError(error);
          });
    } catch (e) {
      webSocketOnError(e);
    }
  }

  /// WebSocket关闭连接回调
  void webSocketOnDone() {
    // 只有当前是连接状态才标记为关闭并重连（避免重复重连）
    if (_socketStatus == SocketStatus.socketStatusConnected) {
      _socketStatus = SocketStatus.socketStatusClosed;
      destroyHeartBeat(); // 连接关闭时销毁心跳
      reconnect();
    }
  }

  /// WebSocket连接错误回调
  void webSocketOnError(dynamic error) {
    print('WebSocket错误: $error');
    _socketStatus = SocketStatus.socketStatusFailed;
    _onError?.call(error.toString());

    destroyHeartBeat(); // 出错时销毁心跳
    reconnect();
  }

  /// 初始化心跳
  void initHeartBeat() {
    destroyHeartBeat(); // 先销毁旧的心跳

    _heartBeat = Timer.periodic(Duration(milliseconds: _heartInterval), (
      timer,
    ) {
      if (_socketStatus == SocketStatus.socketStatusConnected) {
        sentHeart();
      } else {
        destroyHeartBeat();
      }
    });
  }

  /// 发送心跳
  void sentHeart() {
    sendMessage('heartbeat');
  }

  /// 销毁心跳
  void destroyHeartBeat() {
    if (_heartBeat != null) {
      _heartBeat?.cancel();
      _heartBeat = null;
    }
  }

  /// 关闭WebSocket
  void closeSocket() {
    // 销毁心跳
    destroyHeartBeat();

    // 取消重连
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // 关闭连接
    _webSocket?.sink.close();
    _webSocket = null;

    _socketStatus = SocketStatus.socketStatusClosed;
  }

  /// 发送WebSocket消息
  void sendMessage(dynamic message) {
    if (_socketStatus != SocketStatus.socketStatusConnected) {
      print('发送失败，当前状态: $_socketStatus');
      return;
    }

    try {
      _webSocket?.sink.add(message);
    } catch (e) {
      print('发送消息异常: $e');
    }
  }

  /// 重连机制
  void reconnect() {
    // 正在重连中
    if (_reconnectTimer != null) {
      return;
    }

    _reconnectTimes++;
    print('准备第 $_reconnectTimes 次重连');

    // 使用一次性Timer，而不是periodic！
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectInterval), () {
      _reconnectTimer = null; // 清除定时器引用
      openSocket();
    });
  }

  SocketStatus get socketStatus => _socketStatus;
  int? get webSocketCloseCode => _webSocket?.closeCode;
}

// 工具类实例
final _utility = WebSocketUtility();

// 处理聊天消息
void _handleChatMsg(dynamic msg) {
  // 聊天消息本体
  final message = ChatMessageRes.fromJson(msg);
  // 消息store
  final messageStore = Get.find<MessageController>();
  // 会话store
  final sessionStore = Get.find<ChatSessionStore>();
  // 用户store
  final userController = Get.find<UserController>();
  // 联系人store
  final userContactController = Get.find<UserContactController>();
  // 类型为文本或媒体文件, 如果不是当前活跃会话的消息，弹出消息提示
  // 会话id
  final sessionId = message.sessionId;
  if ([
    MessageTypeEnum.text.type,
    MessageTypeEnum.file.type,
    MessageTypeEnum.systemNotice.type,
    MessageTypeEnum.personCard.type,
  ].contains(message.messageType)) {
    // 联系人类型
    final contactType = message.contactType;
    // 消息内容
    String messageContent = message.messageContent;
    // 消息类型
    final messageType = message.messageType;
    // 如果是群聊，需要再做一下处理
    if (contactType == UserContactTypeEnum.group &&
        messageType != MessageTypeEnum.systemNotice.type) {
      messageContent = '${message.sendUserNickname}: $messageContent';
    }
    // 不是正在活跃的会话，消息提示和新增消息未读数量
    if (message.sessionId != activeSessionId &&
        message.sendUserId != userController.userInfo.value?.userId) {
      final contactId = contactType == UserContactTypeEnum.group
          ? message.contactId
          : message.sendUserId;
      // 根据发送方的contactId获取备注
      final contact = userContactController.getUserContact(contactId ?? '');
      // 新增未读数量
      messageStore.addSessionUnreadCount(sessionId);
      // 消息免打扰的会话不弹提示（未读数量正常增加）
      final isDisturb = contact?.disturb == DisturbStatusEnum.open;
      if (!isDisturb) {
        // 展示消息提示
        MessageUtils.show(
          contactId: contactId ?? '',
          contactName: contact?.contactName ?? '...',
          msg: messageContent,
          sendTime: message.sendTime,
          onTap: () {
            // 跳转到聊天消息页面
            navigateToPage(
              RoutePath.chatMessage,
              arguments: {
                'contactId': contactId,
                'contactType': contactType,
                'sessionId': sessionId,
              },
            );
          },
        );
      }
    }
    // 更新会话的lastMessage和lastReceiveTime
    sessionStore.updateLastMessage(sessionId, messageContent, message.sendTime);
  }
  // 通知对应的页面(可能是聊天页面或者语音/视频通话页面)
  eventBus.fire(ServerMsgEvent(type: ServerMsgType.chat, msg: message));
  // 如果是视频通话，跳转到视频通话页面
  if (message.messageType == MessageTypeEnum.videoCall.type) {
    navigateToPage(
      RoutePath.videoCall,
      arguments: {
        'isCaller': false,
        'contactId': message.sendUserId,
        'messageId': message.messageId,
      },
    );
    // 更新会话的lastMessage和lastReceiveTime
    sessionStore.updateLastMessage(
      sessionId,
      message.messageContent,
      message.sendTime,
    );
  } else if (message.messageType == MessageTypeEnum.voiceCall.type) {
    navigateToPage(
      RoutePath.voiceCall,
      arguments: {
        'isCaller': false,
        'contactId': message.sendUserId,
        'messageId': message.messageId,
      },
    );
    // 更新会话的lastMessage和lastReceiveTime
    sessionStore.updateLastMessage(
      sessionId,
      message.messageContent,
      message.sendTime,
    );
  }
}

// 处理联系人申请
void _handleContactApply(dynamic msg) {
  // 联系人申请
  final apply = ContactApplyRes.fromJson(msg);
  // 消息store
  final messageStore = Get.find<MessageController>();
  // 如果不在联系人申请页面，不需要发送eventBus(因为也收不到)，消息提示即可
  if (activeSessionId != UnreadType.contactApply) {
    MessageUtils.show(
      msg: apply.applyInfo,
      contactId: apply.applyUserId,
      contactName: apply.contactName,
      sendTime: apply.applyTime,
      onTap: () {
        // 跳转到联系人申请页面
        navigateToPage(RoutePath.newFriend);
      },
    );
    // 新增联系人申请未读数量
    messageStore.addUnreadCount(UnreadType.contactApply);
  } else {
    eventBus.fire(ServerMsgEvent(type: ServerMsgType.contactApply, msg: apply));
  }
}

// 处理新增联系人
void _handleAddContact(dynamic msg) {
  final message = AddContactMsg.fromJson(msg);
  // 联系人store
  final contactStore = Get.find<UserContactController>();
  // 会话store
  final sessionStore = Get.find<ChatSessionStore>();
  // 新增联系人
  contactStore.addContact(message.contactType, message.contact);
  // 新增会话
  sessionStore.addSession(message.session);
}

// 处理更新消息未读数量
void _handleUnreadCount(List<dynamic> msg) {
  // 消息store
  final messageStore = Get.find<MessageController>();
  for (final item in msg) {
    final sessionId = item['sessionId'];
    final unreadCount = item['unreadCount'];
    // 新增其他类型未读数量
    if ([UnreadType.contactApply, UnreadType.share].contains(sessionId)) {
      messageStore.addUnreadCountByStep(sessionId, unreadCount);
    } else {
      // 聊天消息未读数量
      messageStore.addSessionUnreadCountByStep(sessionId, unreadCount);
    }
  }
}

// 处理撤回消息
void _handleRecallMessage(dynamic msg) {
  final message = ChatMessageRes.fromJson(msg);
  final userController = Get.find<UserController>();
  // 消息store
  final messageStore = Get.find<MessageController>();
  // 会话store
  final sessionStore = Get.find<ChatSessionStore>();
  // 联系人store
  final userContactController = Get.find<UserContactController>();
  // 如果是自己发送的消息，不需要处理
  if (message.sendUserId == userController.userInfo.value?.userId) {
    return;
  }
  // 会话id
  final sessionId = message.sessionId;
  // 当前时间
  final now = DateTime.now().millisecondsSinceEpoch;
  // 如果用户在聊天消息页面
  if (activeSessionId == sessionId) {
    // 通知聊天消息页面
    eventBus.fire(
      ServerMsgEvent(type: ServerMsgType.recallMessage, msg: message),
    );
  } else {
    // 不在聊天消息页面，发送一条通知
    // 联系人类型
    final contactType = message.contactType;
    // 会话id
    final sessionId = message.sessionId;
    final contactId = contactType == UserContactTypeEnum.group
        ? message.contactId
        : message.sendUserId;
    final contact = userContactController.getUserContact(contactId ?? '');
    // 新增未读数量
    messageStore.addSessionUnreadCount(sessionId);
    // 展示消息提示
    MessageUtils.show(
      contactId: contactId ?? '',
      contactName: contact?.contactName ?? '...',
      msg: '${message.sendUserNickname}已撤回一条消息',
      sendTime: now,
      onTap: () {
        // 跳转到聊天消息页面
        navigateToPage(
          RoutePath.chatMessage,
          arguments: {
            'contactId': contactId,
            'contactType': contactType,
            'sessionId': sessionId,
          },
        );
      },
    );
  }
  // 更新会话lastMessage
  sessionStore.updateLastMessage(
    sessionId,
    '${message.sendUserNickname}已撤回一条消息',
    now,
  );
}

// 处理解散群聊
void _handleDissolveGroup(dynamic msg) {
  // 消息内容
  final message = ChatMessageRes.fromJson(msg);
  // 会话store
  final sessionStore = Get.find<ChatSessionStore>();
  // 用户store
  final userController = Get.find<UserController>();
  final sessionId = message.sessionId;
  // 如果不存在对应会话或者是自己解散的群聊
  if (!sessionStore.hasSession(sessionId) ||
      userController.userInfo.value?.userId == message.sendUserId) {
    return;
  }
  // 通知消息
  _notifyGroupMessage(message, sessionId, ServerMsgType.dissolveGroup);
}

// 处理更新群聊信息
void _handleUpdateGroup(dynamic msg) {
  // 联系人store
  final contactStore = Get.find<UserContactController>();
  // 会话store
  final sessionStore = Get.find<ChatSessionStore>();
  final groupId = msg['groupId'];
  final sessionId = msg['sessionId'];
  final groupName = msg['groupName'] as String;
  final messageList = (msg['messageList'] as List)
      .map((msg) => ChatMessageRes.fromJson(msg))
      .toList();
  // 更新了群名称
  if (groupName.isNotEmpty) {
    contactStore.updateGroupName(groupId, groupName);
    sessionStore.updateContactName(groupName, sessionId: sessionId);
  }
  // 通知消息
  for (final message in messageList) {
    _notifyGroupMessage(message, sessionId, ServerMsgType.chat);
  }
  if (sessionId == activeSessionId && groupName.isNotEmpty) {
    eventBus.fire(
      ServerMsgEvent(type: ServerMsgType.updateGroup, msg: groupName),
    );
  }
}

// 处理服务器推送的消息
void _handleServerMsg(dynamic msg) {
  final serverMsg = ServerMsgEvent.fromJson(jsonDecode(msg));
  print('服务器推送的消息: $serverMsg');
  // 聊天消息
  if (serverMsg.type == ServerMsgType.chat) {
    _handleChatMsg(serverMsg.msg);
  } else if (serverMsg.type == ServerMsgType.contactApply) {
    // 联系人申请
    _handleContactApply(serverMsg.msg);
  } else if (serverMsg.type == ServerMsgType.addContact) {
    // 新增联系人
    _handleAddContact(serverMsg.msg);
  } else if (serverMsg.type == ServerMsgType.unreadCount) {
    // 更新消息未读数量
    _handleUnreadCount(serverMsg.msg);
  } else if (serverMsg.type == ServerMsgType.recallMessage) {
    // 撤回消息
    _handleRecallMessage(serverMsg.msg);
  } else if (serverMsg.type == ServerMsgType.dissolveGroup) {
    // 解散群聊
    _handleDissolveGroup(serverMsg.msg);
  } else if (serverMsg.type == ServerMsgType.updateGroup) {
    // 更新群聊信息
    _handleUpdateGroup(serverMsg.msg);
  }
}

// 通知群聊消息
void _notifyGroupMessage(
  ChatMessageRes message,
  String sessionId,
  String type,
) {
  // 会话store
  final sessionStore = Get.find<ChatSessionStore>();
  // 消息store
  final messageStore = Get.find<MessageController>();
  // 发送时间
  final sendTime = message.sendTime;
  // 消息内容
  final messageContent = message.messageContent;
  // 联系人store
  final userContactController = Get.find<UserContactController>();
  // 就在当前群聊
  if (sessionId == activeSessionId) {
    // 通知聊天消息页面
    eventBus.fire(ServerMsgEvent(type: type, msg: message));
  } else {
    final contactId = message.contactId;
    final contact = userContactController.getUserContact(contactId);
    // 新增未读数量
    messageStore.addSessionUnreadCount(sessionId);
    // 展示消息提示
    MessageUtils.show(
      contactId: contactId,
      contactName: contact?.contactName ?? '',
      msg: messageContent,
      sendTime: sendTime,
      onTap: () {
        // 跳转到聊天消息页面
        navigateToPage(
          RoutePath.chatMessage,
          arguments: {
            'contactId': contactId,
            'contactType': UserContactTypeEnum.group,
            'sessionId': sessionId,
          },
        );
      },
    );
  }
  // 更新会话lastMessage
  sessionStore.updateLastMessage(sessionId, messageContent, sendTime);
}

// 初始化websocket
void initWebSocket() {
  _utility.initWebSocket(
    onOpen: () {
      print('$websocketUrl连接成功...');
    },
    onMessage: _handleServerMsg,
    onError: (e) {
      print('WebSocket错误: $e');
    },
  );
}

// 断开websocket连接
void closeWebSocket() {
  _utility.closeSocket();
}

// 活跃的会话id
String activeSessionId = '';

// 设置活跃会话
void setActiveSession(String sessionId) {
  activeSessionId = sessionId;
}

// 删除活跃会话
void removeActiveSession() {
  activeSessionId = '';
}
