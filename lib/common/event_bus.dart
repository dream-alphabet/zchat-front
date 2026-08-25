import 'package:event_bus/event_bus.dart';

// 服务器推送消息事件
class ServerMsgEvent<T> {
  // 消息类型
  final String type;
  // 消息本体
  final T msg;

  ServerMsgEvent({required this.type, required this.msg});

  factory ServerMsgEvent.fromJson(Map<String, dynamic> json) =>
      ServerMsgEvent(type: json['type'] ?? '', msg: json['msg']);

  @override
  String toString() {
    return 'ServerMsgEvent{'
        'type: $type, '
        'msg: $msg'
        '}';
  }
}

// 服务器推送消息类型
class ServerMsgType {
  // 聊天消息
  static const chat = 'chat';
  // 联系人申请
  static const contactApply = 'contactApply';
  // 新增联系人
  static const addContact = 'addContact';
  // 更新消息未读数量
  static const unreadCount = 'unreadCount';
  // 撤回消息
  static const recallMessage = 'recallMessage';
  // 群聊解散
  static const dissolveGroup = 'dissolveGroup';
  // 更新群聊信息
  static const updateGroup = 'updateGroup';
  // 机器人输入中
  static const aiTyping = 'aiTyping';
}

// 全局事件总线
final eventBus = EventBus();
