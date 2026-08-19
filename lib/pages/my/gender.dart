import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/user.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/user.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/page_header.dart';

// 性别选择
class GenderPage extends StatefulWidget {
  const GenderPage({super.key});

  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  // 用户store
  final _userController = Get.find<UserController>();

  // 更新性别
  Future<void> _updateGender(int gender) async {
    final user = await updateUserInfoApi(UpdateUserInfoReq(gender: gender));
    _userController.userInfo.value = user;
    ToastUtils.showGlobalToast(msg: '设置成功');
    if (!mounted) return;
    Navigator.pop(context);
  }

  // 性别选项行
  Widget _buildOptionRow(String title, int gender, bool showBorder) {
    final selected = _userController.userInfo.value?.gender == gender;
    return InkWell(
      onTap: () => _updateGender(gender),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 15.w),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: const Color.fromRGBO(237, 237, 237, 1),
                    width: 1.w,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 16.sp)),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected
                  ? const Color.fromRGBO(20, 134, 237, 1)
                  : const Color.fromRGBO(174, 174, 174, 1),
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: const Color.fromRGBO(237, 237, 237, 1),
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: const Color.fromRGBO(237, 237, 237, 1),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '性别',
              showLeftBackIcon: true,
              backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
              showRightIcon: false,
              showBorder: false,
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Obx(
                () => Column(
                  children: [
                    _buildOptionRow('男', 1, true),
                    _buildOptionRow('女', 0, false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
