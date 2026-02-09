import 'package:get/get.dart';
import 'package:zchat/model/user.dart';

// 用户信息store
class UserController extends GetxController {
  // 用户信息
  final userInfo = (null as UserInfo?).obs;

  // 更新用户信息
  void setUserInfo(UserInfo newUserInfo) {
    userInfo.value = newUserInfo;
  }

  // 获取用户信息
  UserInfo? getUserInfo() {
    return userInfo.value;
  }
}
