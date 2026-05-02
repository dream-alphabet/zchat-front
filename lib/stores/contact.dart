import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';

// 联系人store
class UserContactController extends GetxController {
  // 联系人列表
  final userList = (<UserContactRes>[]).obs;
  // 群聊列表
  final groupList = (<UserContactRes>[]).obs;

  // 获取联系人列表
  Future<void> getUserContactList() async {
    userList.value = await getContactListApi(UserContactTypeEnum.user);
  }

  // 获取群聊列表
  Future<void> getGroupList() async {
    groupList.value = await getContactListApi(UserContactTypeEnum.group);
  }
}