import 'package:zchat/api/request.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/group.dart';

// 创建群聊
Future<void> createGroupApi(CreateGroupReq data) async {
  await request.post(Api.createGroup, data: data.toJson(), isFormData: true);
}

// 获取群聊设置信息
Future<GetGroupSettingsRes> getGroupSettingsApi(String groupId) async {
  return GetGroupSettingsRes.fromJson(
    await request.get(Api.getGroupSettings + groupId),
  );
}

// 搜索群成员
Future<List<UserContactRes>> searchGroupMemberApi(
  String groupId,
  String keywords,
) async {
  final list = List.from(
    await request.get(
      Api.searchGroupMember,
      params: {'groupId': groupId, 'keywords': keywords},
    ),
  );
  return List.generate(
    list.length,
    (index) => UserContactRes.fromJson(list[index]),
  );
}

// 解散群聊
Future<void> dissolveGroupApi(String groupId) async {
  await request.get(Api.dissolveGroup + groupId);
}
