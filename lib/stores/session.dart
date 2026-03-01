import 'package:get/get.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/model/chat.dart';

// 聊天会话store
class ChatSessionStore extends GetxController {
  // 会话列表
  final sessionList = (<ChatSessionRes>[]).obs;

  // 获取会话列表
  Future<void> getSessionList() async {
    sessionList.value = await getChatSessionListApi();
  }
}