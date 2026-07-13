import 'package:zchat/api/request.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/common.dart';

// 获取会话列表
Future<List<ChatSessionRes>> getChatSessionListApi() async {
  final list = List.from(await request.get(Api.getChatSessionList));
  return List.generate(
    list.length,
    (index) => ChatSessionRes.fromJson(list[index]),
  );
}

// 发送消息
Future<ChatMessageRes> sendMessageApi(SendMsgReq data) async {
  return ChatMessageRes.fromJson(
    await request.post(Api.sendMessage, data: data.toJson(), isFormData: true),
  );
}

// 获取消息列表
Future<PageRes> getMessageListApi(GetMsgListReq data) async {
  return PageRes.fromJson(
    await request.get(Api.getMsgList, params: data.toMap()),
  );
}

// 撤回消息
Future<void> recallMessageApi(int messageId) async {
  await request.get(Api.recallMessage + messageId.toString());
}

// 转发消息
Future<ChatMessageRes> shareMessageApi(ShareMsgReq data) async {
  return ChatMessageRes.fromJson(
    await request.post(Api.shareMessage, data: data.toJson()),
  );
}
