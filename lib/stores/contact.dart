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

  // 新增联系人
  void addContact(int contactType, UserContactRes contact) {
    if (UserContactTypeEnum.group == contactType) {
      groupList.add(contact);
    } else if (UserContactTypeEnum.user == contactType) {
      userList.add(contact);
    }
  }

  // 删除联系人
  void del(String contactId, int contactType) {
    if (UserContactTypeEnum.group == contactType) {
      delGroup(contactId);
    } else if (UserContactTypeEnum.user == contactType) {
      delContact(contactId);
    }
  }

  // 删除好友
  void delContact(String userId) {
    userList.removeWhere((contact) => contact.contactId == userId);
  }

  // 删除群聊
  void delGroup(String groupId) {
    groupList.removeWhere((group) => group.contactId == groupId);
  }

  // 更新群名称
  void updateGroupName(String groupId, String groupName) {
    final index = groupList.indexOf((group) => group.contactId == groupId);
    if (index != -1) {
      final group = groupList[index];
      group.originName = groupName;
      groupList[index] = group;
    }
  }

  // 查找联系人
  UserContactRes? findUserContact(String contactId, int contactType) {
    if (UserContactTypeEnum.group == contactType) {
      return groupList.firstWhereOrNull((g) => g.contactId == contactId);
    } else if (UserContactTypeEnum.user == contactType) {
      return userList.firstWhereOrNull((c) => c.contactId == contactId);
    }
    return null;
  }

  // 更新备注
  void updateRemark(String contactId, String remark) {
    final group = groupList.firstWhereOrNull((g) => g.contactId == contactId);
    if (group != null) {
      group.remark = remark;
      return;
    }
    final user = userList.firstWhereOrNull((c) => c.contactId == contactId);
    if (user != null) {
      user.remark = remark;
    }
  }
}
