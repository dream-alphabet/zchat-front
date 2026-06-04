import 'package:event_bus/event_bus.dart';
import 'package:zchat/model/chat.dart';

// 服务器推送消息事件
class ServerMsgEvent {
  final ChatMessageRes msg;

  ServerMsgEvent({required this.msg});
}

// 全局事件总线
final eventBus = EventBus();