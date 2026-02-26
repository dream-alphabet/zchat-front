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
