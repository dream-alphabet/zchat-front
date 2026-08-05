import 'package:zchat/api/request.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/common.dart';
import 'package:zchat/model/contact.dart';

// 查询用户/群组是否存在
Future<bool> searchContactExistApi(String keyword) async {
  return (await request.get(
    Api.searchContactExist,
    params: {'keyword': keyword},
  ));
}

// 获取联系人(用户/群组)信息
Future<ContactInfoRes?> getContactInfoApi(String contactId) async {
  final result = await request.get(
    Api.getContactInfo,
    params: {'contactId': contactId},
  );
  if (result == null) {
    return null;
  }
  return ContactInfoRes.fromJson(result);
}

// 发送添加朋友申请
Future<int> sendContactApplyApi(SendApplyReq data) async {
  return (await request.post(Api.sendContactApply, data: data.toJson()));
}

// 获取联系人申请列表
Future<PageRes> getContactApplyListApi(ApplyListReq req) async {
  return PageRes.fromJson(
    (await request.get(Api.getContactApplyList, params: req.toMap())),
  );
}

// 处理联系人申请
Future<void> handleApplyApi(HandleApplyReq req) {
  return request.get(Api.handleApply, params: req.toMap());
}

// 获取联系人列表
Future<List<UserContactRes>> getContactListApi(int contactType) async {
  final list = List.from(
    await request.get(Api.getContactList, params: {'contactType': contactType}),
  );
  return List.generate(
    list.length,
    (index) => UserContactRes.fromJson(list[index]),
  );
}

// 搜索联系人
Future<List<UserContactRes>> searchContactApi(SearchContactReq req) async {
  final list = List.from(
    await request.get(Api.searchContact, params: req.toJson()),
  );
  return List.generate(
    list.length,
    (index) => UserContactRes.fromJson(list[index]),
  );
}

// 删除联系人
Future<void> delContactApi(String contactId, int contactType) async {
  await request.get(
    Api.delContact,
    params: {'contactId': contactId, 'contactType': contactType},
  );
}

// 更新联系人设置
Future<void> updateContactSettingApi(UpdateContactSettingReq data) async {
  await request.post(Api.updateContactSetting, data: data.toJson());
}
