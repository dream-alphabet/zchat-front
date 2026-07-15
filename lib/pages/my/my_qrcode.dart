import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/common.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/dialog.dart';
import 'package:zchat/widgets/page_header.dart';
import 'package:zchat/widgets/qrcode.dart';

// 我的二维码
class MyQrcodePage extends StatefulWidget {
  const MyQrcodePage({super.key});

  @override
  State<MyQrcodePage> createState() => _MyQrcodePageState();
}

class _MyQrcodePageState extends State<MyQrcodePage> {
  // 用户store
  final _userController = Get.find<UserController>();
  // 二维码key
  final _qrcodeKey = GlobalKey();

  // 保存二维码到相册
  void _saveToGallery() async {
    // 判断是否有相册权限
    final status = await requestGalleryPermission();
    if (status.isDenied) {
      showPromptDialog(context, '没有权限, 请重试');
      return;
    }
    final boundry =
        _qrcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    // 没有获取到二维码widget
    if (boundry == null) {
      showPromptDialog(context, '保存失败');
      return;
    }
    // 转换成图片
    final image = await boundry.toImage();
    final byteData = await image.toByteData(format: .png);
    if (byteData == null) {
      showPromptDialog(context, '保存失败');
      return;
    }
    // 保存图片
    await Gal.putImageBytes(byteData.buffer.asUint8List());
    showPromptDialog(context, '保存成功');
  }

  // 构建二维码
  Widget _buildQrCode() {
    // 二维码数据
    final data = QrCodeData(
      type: QrCodeType.person.type,
      data: _userController.userInfo.value?.userId ?? '',
    );
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(vertical: 40.w),
      child: RepaintBoundary(
        key: _qrcodeKey,
        child: Container(
          color: Colors.white,
          child: Qrcode(data: jsonEncode(data.toJson())),
        ),
      ),
    );
  }

  // 构建二维码操作区域
  Widget _buildQrcodeBtns() {
    return Row(
      mainAxisAlignment: .center,
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 10.w),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, RoutePath.scan);
            },
            child: Text(
              '扫一扫',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color.fromRGBO(83, 106, 149, 1),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 10.w),
          child: GestureDetector(
            onTap: _saveToGallery,
            child: Text(
              '保存到相册',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color.fromRGBO(83, 106, 149, 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建我的二维码区域
  Widget _buildMyQrCode() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 10.w),
      child: Container(
        width: double.infinity,
        padding: .all(15.w),
        decoration: BoxDecoration(
          borderRadius: .circular(8.r),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: .start,
              spacing: 10.w,
              children: [
                Icon(
                  MyIcon.myQrCode,
                  color: const Color.fromRGBO(20, 134, 237, 1),
                  size: 18.sp,
                ),
                Text('添加我为朋友'),
                Expanded(child: SizedBox()),
                ContactAvatar(
                  contactId: _userController.userInfo.value?.userId ?? '',
                  shape: .rectangle,
                ),
                Text(_userController.userInfo.value?.nickname ?? ''),
              ],
            ),
            _buildQrCode(),
            Text(
              '扫二维码，添加我为朋友',
              style: TextStyle(
                color: const Color.fromRGBO(177, 177, 177, 1),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 40.w),
            _buildQrcodeBtns(),
            SizedBox(height: 30.w),
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
        backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: const Color.fromRGBO(247, 247, 247, 1), // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: const Color.fromRGBO(
            247,
            247,
            247,
            1,
          ), // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
      body: SafeArea(
        child: ListView(
          children: [
            PageHeader(
              title: '我的二维码',
              showLeftBackIcon: true,
              showRightIcon: false,
              showBorder: false,
            ),
            _buildMyQrCode(),
          ],
        ),
      ),
    );
  }
}
