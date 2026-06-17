import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zchat/api/user.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/user.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/bottom_sheet.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 用户中心页面
class MyPage extends StatefulWidget {
  final void Function()? onBack;

  const MyPage({super.key, this.onBack});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // 用户store
  final _userController = Get.find<UserController>();

  // 修改头像
  void _updateAvatar(ImageSource source) async {
    // 选择图片
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      // 文件路径
      final path = image.path;
      // 文件名
      final filename = image.name;
      // 文件大小
      final fileSize = await image.length();
      // 校验文件大小
      if (fileSize > GlobalConstants.imageMaxSize) {
        return ToastUtils.showGlobalToast(
          msg: '图片不能大于${GlobalConstants.imageMaxMB}MB',
        );
      }
      // 封装multipart
      final file = await MultipartFile.fromFile(path, filename: filename);
      // 调用更新头像接口
      await updateUserAvatarApi(UpdateAvatarReq(avatar: file));
      // 刷新头像
      AvatarGlobal.refresh(_userController.userInfo.value?.userId ?? '-1');
    }
    // 关闭sheet
    Navigator.pop(context);
  }

  // 显示修改头像sheet
  void _showUpdateSheet() {
    showMyBottomSheet(context, [
      SheetItem('从相册中选择图片', () {
        _updateAvatar(ImageSource.gallery);
      }),
      SheetItem('拍照', () {
        _updateAvatar(ImageSource.camera);
      }),
    ]);
  }

  // 返回上一页
  void _goBack() {
    // 判断当前路由是个人中心还是主页
    final routeName = ModalRoute.of(context)!.settings.name;
    // 是个人中心页面，说明是跳转过来的
    if (routeName == RoutePath.my) {
      Navigator.pop(context);
    } else {
      // 不是说明是在main主页
      if (widget.onBack != null) {
        widget.onBack!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('用户中心')),
      body: Center(
        child: Column(
          spacing: 5.w,
          mainAxisAlignment: .center,
          children: [
            ContactAvatar(
              contactId: _userController.userInfo.value?.userId ?? '-1',
            ),
            ElevatedButton(onPressed: _showUpdateSheet, child: Text('修改头像')),
            ElevatedButton(onPressed: _goBack, child: Text('返回')),
          ],
        ),
      ),
    );
  }
}
