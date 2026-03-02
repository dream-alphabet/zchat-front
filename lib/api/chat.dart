import 'package:zchat/api/request.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/chat.dart';

// 获取会话列表
Future<List<ChatSessionRes>> getChatSessionListApi() async {
  final list = List.from(await request.get(Api.getChatSessionList));
  return List.generate(
    list.length,
    (index) => ChatSessionRes.fromJson(list[index]),
  );
}

// 发送消息
Future<void> sendMessageApi(SendMsgReq data) {
  return request.post(Api.sendMessage, data: data.toJson(), isFormData: true);
}