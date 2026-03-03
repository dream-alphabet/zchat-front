import 'package:event_bus/event_bus.dart';

// 服务器推送消息事件
class ServerMsgEvent {
  final dynamic msg;

  ServerMsgEvent({required this.msg});
}

// 全局事件总线
final eventBus = EventBus();