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
  final int _heartInterval = 3000; // 心跳间隔
  final int _reconnectCount = 5; // 最大重连次数
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
      print('Token为空，无法连接WebSocket');
      return;
    }

    // 如果已有连接，先关闭
    closeSocket();

    _socketStatus = SocketStatus.socketStatusConnecting;

    final url = '$websocketUrl?token=$token';
    print('WebSocket连接中: $url');

    try {
      _webSocket = WebSocketChannel.connect(Uri.parse(url));

      // 监听连接就绪
      _webSocket!.ready
          .then((_) {
            print('WebSocket连接成功');
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
                print('WebSocket错误: $error');
                webSocketOnError(error);
              },
              onDone: webSocketOnDone,
            );
          })
          .catchError((error) {
            print('WebSocket连接失败: $error');
            webSocketOnError(error);
          });
    } catch (e) {
      print('WebSocket连接异常: $e');
      webSocketOnError(e);
    }
  }

  /// WebSocket关闭连接回调
  void webSocketOnDone() {
    print(
      'WebSocket连接关闭: code=${_webSocket?.closeCode}, reason=${_webSocket?.closeReason}',
    );

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

    print('启动心跳，间隔: ${_heartInterval}ms');
    _heartBeat = Timer.periodic(Duration(milliseconds: _heartInterval), (
      timer,
    ) {
      if (_socketStatus == SocketStatus.socketStatusConnected) {
        sentHeart();
      } else {
        print('连接已断开，停止心跳');
        destroyHeartBeat();
      }
    });
  }

  /// 发送心跳
  void sentHeart() {
    print('发送心跳');
    sendMessage('heartbeat');
  }

  /// 销毁心跳
  void destroyHeartBeat() {
    if (_heartBeat != null) {
      print('销毁心跳定时器');
      _heartBeat?.cancel();
      _heartBeat = null;
    }
  }

  /// 关闭WebSocket
  void closeSocket() {
    print('主动关闭WebSocket连接');

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
      print('发送消息: $message');
      _webSocket?.sink.add(message);
    } catch (e) {
      print('发送消息异常: $e');
    }
  }

  /// 重连机制
  void reconnect() {
    // 如果已经在重连中，或者超过最大次数，则不再重连
    if (_reconnectTimer != null || _reconnectTimes >= _reconnectCount) {
      if (_reconnectTimes >= _reconnectCount) {
        print('重连次数超过最大次数($_reconnectCount)，停止重连');
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
      }
      return;
    }

    _reconnectTimes++;
    print('准备第 $_reconnectTimes 次重连，${_reconnectInterval}ms后重试...');

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
  // 类型为文本或媒体文件, 如果不是当前活跃会话的消息，弹出消息提示
  if ([
    MessageTypeEnum.text.type,
    MessageTypeEnum.file.type,
  ].contains(message.messageType)) {
    // 联系人类型
    final contactType = message.contactType;
    // 会话id
    final sessionId = message.sessionId;
    // 消息内容
    String messageContent = message.messageContent;
    // 如果是群聊，需要再做一下处理
    if (contactType == UserContactTypeEnum.group) {
      messageContent = '${message.sendUserNickname}: $messageContent';
    }
    // 不是正在活跃的会话，消息提示和新增消息未读数量
    if (message.sessionId != activeSessionId) {
      final contactId = contactType == UserContactTypeEnum.group
          ? message.contactId
          : message.sendUserId;
      final contactName = contactType == UserContactTypeEnum.group
          ? message.contactName
          : message.sendUserNickname;
      // 新增未读数量
      messageStore.addSessionUnreadCount(sessionId);
      // 展示消息提示
      MessageUtils.show(
        contactId: contactId ?? '',
        contactName: contactName ?? '...',
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
    // 更新会话的lastMessage和lastReceiveTime
    sessionStore.updateLastMessage(sessionId, messageContent, message.sendTime);
  }
  eventBus.fire(ServerMsgEvent(type: ServerMsgType.chat, msg: message));
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
  }
}

// 初始化websocket
void initWebSocket() {
  _utility.initWebSocket(
    onOpen: () {
      print('WebSocket已开启');
    },
    onMessage: _handleServerMsg,
    onError: (e) {
      print('WebSocket错误: $e');
    },
  );
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
