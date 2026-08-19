import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/user.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/user.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/page_header.dart';

// 个性签名编辑
class PersonDescPage extends StatefulWidget {
  const PersonDescPage({super.key});

  @override
  State<PersonDescPage> createState() => _PersonDescPageState();
}

class _PersonDescPageState extends State<PersonDescPage> {
  // 用户store
  final _userController = Get.find<UserController>();
  // 签名输入框控制器
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 设置当前签名
    _descController.text = _userController.userInfo.value?.personDesc ?? '';
  }

  // 保存个性签名(空文本则清空签名)
  Future<void> _save() async {
    final desc = _descController.text.trim();
    final user = await updateUserInfoApi(UpdateUserInfoReq(personDesc: desc));
    _userController.userInfo.value = user;
    ToastUtils.showGlobalToast(msg: '已保存');
    if (!mounted) return;
    Navigator.pop(context);
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
              title: '个性签名',
              showLeftBackIcon: true,
              backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
              showRightIcon: true,
              showBorder: false,
              rightIconList: [
                GestureDetector(
                  onTap: _save,
                  child: Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: const Color.fromRGBO(20, 134, 237, 1),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.w),
              color: Colors.white,
              padding: EdgeInsets.all(15.w),
              child: TextField(
                controller: _descController,
                maxLength: 200,
                maxLines: 3,
                style: TextStyle(color: Colors.black, fontSize: 16.sp),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '请输入个性签名',
                  hintStyle: TextStyle(
                    color: const Color.fromRGBO(178, 178, 178, 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
