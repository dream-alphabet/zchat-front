import 'package:get/get.dart';
import 'package:zchat/api/user.dart';
import 'package:zchat/model/user.dart';

// 用户信息store
class UserController extends GetxController {
  // 用户信息
  final userInfo = (null as UserInfo?).obs;

  // 获取用户信息
  Future<void> getUserInfo() async {
    userInfo.value = await getUserInfoApi();
  }
}
