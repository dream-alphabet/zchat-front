import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';

// 联系人store
class UserContactController extends GetxController {
  // 联系人列表
  final contactList = (<UserContactRes>[]).obs;

  // 获取联系人列表
  Future<void> getContactList() async {
    contactList.value = await getContactListApi(UserContactTypeEnum.user);
  }
}