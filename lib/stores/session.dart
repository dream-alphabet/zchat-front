import 'package:get/get.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/model/chat.dart';

// 聊天会话store
class ChatSessionStore extends GetxController {
  // 会话列表
  final sessionList = (<ChatSessionRes>[]).obs;

  // 更新contactName
  void updateContactName(
    String contactName, {
    String? sessionId,
    String? contactId,
  }) {
    final index = sessionList.indexWhere(
      (s) => s.sessionId == sessionId || s.contactId == contactId,
    );
    if (index != -1) {
      sessionList[index] = sessionList[index].copyWith(originName: contactName);
    }
  }

  // 更新备注
  void updateRemark(String remark, {String? sessionId, String? contactId}) {
    final index = sessionList.indexWhere(
      (s) => s.sessionId == sessionId || s.contactId == contactId,
    );
    if (index != -1) {
      sessionList[index] = sessionList[index].copyWith(remark: remark);
    }
  }

  // 更新会话免打扰状态
  void updateDisturb(String contactId, int disturb) {
    final index = sessionList.indexWhere((s) => s.contactId == contactId);
    if (index != -1) {
      sessionList[index] = sessionList[index].copyWith(disturb: disturb);
    }
  }

  // 更新会话的lastMessage和lastReceiveTime
  void updateLastMessage(
    String sessionId,
    String lastMessage,
    int lastReceiveTime,
  ) {
    final index = sessionList.indexWhere((s) => s.sessionId == sessionId);
    if (index != -1) {
      sessionList[index] = sessionList[index].copyWith(
        lastMessage: lastMessage,
        lastReceiveTime: lastReceiveTime,
      );
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

  // 删除指定会话
  void delSession(String contactId) {
    sessionList.removeWhere((session) => session.contactId == contactId);
  }

  // 是否存在指定会话
  bool hasSession(String sessionId) {
    return sessionList.firstWhereOrNull(
          (session) => session.sessionId == sessionId,
        ) !=
        null;
  }
}
