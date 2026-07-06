import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/common.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/page_header.dart';
import 'package:zchat/widgets/qrcode.dart';

// 添加朋友
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  // 用户信息store
  final _userController = Get.find<UserController>();

  // 搜索框
  Widget _buildSearch() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 5.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.w),
        color: Color.fromRGBO(241, 241, 241, 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10.w,
        children: [
          Icon(
            MyIcon.search,
            size: 16.sp,
            color: Color.fromRGBO(169, 169, 169, 1),
          ),
          Text(
            '搜索 邮箱/用户id/群id',
            style: TextStyle(
              fontSize: 16.sp,
              color: Color.fromRGBO(169, 169, 169, 1),
            ),
          ),
        ],
      ),
    );
  }

  // 扫一扫
  Widget _buildScan() {
    return Row(
      spacing: 25.w,
      children: [
        Icon(MyIcon.scan, size: 25.w, color: Color.fromRGBO(20, 134, 237, 1)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3.w,
            children: [
              Text(
                '扫一扫',
                style: TextStyle(fontSize: 15.sp, color: Colors.black),
              ),
              Text(
                '扫描二维码名片',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Color.fromRGBO(172, 172, 172, 1),
                ),
              ),
            ],
          ),
        ),
        Icon(
          MyIcon.arrowRight,
          color: Color.fromRGBO(179, 179, 179, 1),
          size: 15.w,
        ),
      ],
    );
  }

  // 构建上半部分
  Widget _buildTop() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, RoutePath.searchContact);
            },
            child: _buildSearch(),
          ),
          SizedBox(height: 20.w),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pushNamed(context, RoutePath.scan);
            },
            child: _buildScan(),
          ),
        ],
      ),
    );
  }

  // 二维码
  Widget _buildQrCode() {
    // 二维码数据
    final data = QrCodeData(
      type: QrCodeType.person.type,
      data: _userController.userInfo.value?.userId ?? '',
    );
    return Qrcode(data: jsonEncode(data.toJson()), size: 240);
  }

  // 构建下半部分
  Widget _buildBottom() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 50.w,
      children: [
        _buildQrCode(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            copyText(_userController.userInfo.value?.userId ?? '');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10.w,
            children: [
              Text(
                '用户id: ${_userController.userInfo.value?.userId ?? ''}',
                style: TextStyle(color: Colors.black, fontSize: 18.sp),
              ),
              Icon(Icons.copy, size: 18.sp),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white, // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          PageHeader(
            title: '添加朋友',
            showLeftBackIcon: true,
            showRightIcon: false,
            showBorder: false,
            backgroundColor: Colors.white,
          ),
          _buildTop(),
          Expanded(child: _buildBottom()),
        ],
      ),
    );
  }
}
