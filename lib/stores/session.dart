import 'package:get/get.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/model/chat.dart';

// 聊天会话store
class ChatSessionStore extends GetxController {
  // 会话列表
  final sessionList = (<ChatSessionRes>[]).obs;

  // 更新会话的lastMessage和lastReceiveTime
  void updateLastMessage(
    String sessionId,
    String lastMessage,
    int lastReceiveTime,
  ) {
    // 查找对应的session
    final session = sessionList.firstWhereOrNull(
      (session) => session.sessionId == sessionId,
    );
    if (session != null) {
      session.lastMessage = lastMessage;
      session.lastReceiveTime = lastReceiveTime;
      // 刷新会话列表，触发更新
      sessionList.refresh();
    }
  }

  // 获取会话列表
  Future<void> getSessionList() async {
    sessionList.value = await getChatSessionListApi();
  }

  // 新增会话
  void addSession(ChatSessionRes session) {
    sessionList.add(session);
  }
}
