import 'package:zchat/api/request.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/contact.dart';

// 查询用户/群组是否存在
Future<bool> searchContactExistApi(String keyword) async {
  return (await request.get(Api.searchContactExist, params: {'keyword': keyword}));
}

// 获取联系人(用户/群组)信息
Future<ContactInfoRes?> getContactInfoApi(String contactId) async {
  final result = await request.get(Api.getContactInfo, params: {'contactId': contactId});
  if (result == null) {
    return null;
  }
  return ContactInfoRes.fromJson(result);
}
