import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zchat/api/user.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/websocket.dart';
import 'package:zchat/model/user.dart';
import 'package:zchat/stores/token.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/dialog.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/page_header.dart';
import 'package:zchat/widgets/wechat_switch.dart';

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
  // 是否是底部tab展示(不是独立路由打开)
  bool _isTab = true;

  @override
  void initState() {
    super.initState();
    // 判断当前路由是tab还是独立页面
    Future.microtask(() {
      if (!mounted) return;
      if (ModalRoute.of(context) != null) {
        _isTab = ModalRoute.of(context)!.settings.name != RoutePath.my;
        setState(() {});
      }
    });
  }

  // 修改头像
  void _updateAvatar(ImageSource source) async {
    // 选择图片
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    // 非空判断
    if (image == null) {
      return;
    }
    // 让用户可以开始裁切图片
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      // 裁切页面设置
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪头像',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: '裁剪头像'),
      ],
    );
    // 裁切失败
    if (croppedFile == null) {
      return;
    }
    File avatar = File(croppedFile.path);
    // 上传头像
    // 文件路径
    final path = avatar.path;
    // 文件大小
    final fileSize = await avatar.length();
    // 校验文件大小
    if (fileSize > GlobalConstants.imageMaxSize) {
      return ToastUtils.showGlobalToast(
        msg: '头像不能大于${GlobalConstants.imageMaxMB}MB',
      );
    }
    // 封装multipart
    final file = await MultipartFile.fromFile(path);
    // 调用更新头像接口
    await updateUserAvatarApi(UpdateAvatarReq(avatar: file));
    // 刷新头像
    AvatarGlobal.refresh(_userController.userInfo.value?.userId ?? '-1');
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

  // 切换添加类型(加我为朋友时需要验证)
  Future<void> _toggleJoinType(bool value) async {
    final user = await updateUserInfoApi(
      UpdateUserInfoReq(joinType: value ? 1 : 0),
    );
    _userController.userInfo.value = user;
    ToastUtils.showGlobalToast(msg: value ? '已开启验证' : '已关闭验证');
  }

  // 退出登录
  void _logout() async {
    final result = await showPromptDialog(
      context,
      '是否确定退出登录',
      showCancel: true,
    );
    if (result == null || !result) {
      return;
    }
    // 后端删除登录信息
    await logoutApi();
    // 删除token
    tokenManager.removeToken();
    // 断开websocket连接
    closeWebSocket();
    // 关闭所有页面并跳转到登录页面
    Navigator.pushNamedAndRemoveUntil(
      context,
      RoutePath.login,
      (route) => false,
    );
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

  // 性别显示文案
  String get _genderText {
    final gender = _userController.userInfo.value?.gender;
    if (gender == null) {
      return '未设置';
    }
    return gender == 1 ? '男' : '女';
  }

  // 签名显示文案
  String get _personDescText {
    final desc = _userController.userInfo.value?.personDesc;
    if (desc == null || desc.isEmpty) {
      return '未填写';
    }
    return desc;
  }

  // 顶部个人信息卡片
  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 25.w),
      child: Row(
        spacing: 15.w,
        children: [
          GestureDetector(
            onTap: _showUpdateSheet,
            child: ContactAvatar(
              contactId: _userController.userInfo.value?.userId ?? '-1',
              size: 60,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6.w,
              children: [
                Text(
                  _userController.userInfo.value?.nickname ?? '',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userController.userInfo.value?.email ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color.fromRGBO(174, 174, 174, 1),
                  ),
                ),
                Text(
                  _personDescText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color.fromRGBO(174, 174, 174, 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 值文案(灰色)
  Widget _buildValueText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        color: const Color.fromRGBO(174, 174, 174, 1),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  // 列表导航行(图标+标题+值+箭头)
  Widget _buildNavRow({
    Widget? leading,
    required String title,
    Widget? trailing,
    bool showBorder = false,
    VoidCallback? onTap,
  }) {
    return InkClick(
      backgroundColor: Colors.white,
      onTap: onTap,
      child: Container(
        height: 60.w,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
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
          children: [
            if (leading != null) ...[leading, SizedBox(width: 20.w)],
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16.sp)),
            ),
            if (trailing != null) ...[SizedBox(width: 10.w), trailing],
            SizedBox(width: 5.w),
            Icon(
              MyIcon.arrowRight,
              color: const Color.fromRGBO(179, 179, 179, 1),
              size: 15.w,
            ),
          ],
        ),
      ),
    );
  }

  // 退出登录按钮
  Widget _buildLogoutBtn() {
    return InkClick(
      backgroundColor: Colors.white,
      onTap: _logout,
      child: Container(
        height: 60.w,
        alignment: Alignment.center,
        child: Text(
          '退出登录',
          style: TextStyle(
            fontSize: 16.sp,
            color: const Color.fromRGBO(241, 90, 81, 1),
          ),
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
          statusBarColor: const Color.fromRGBO(237, 237, 237, 1), // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: const Color.fromRGBO(
            237,
            237,
            237,
            1,
          ), // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '用户中心',
              showLeftBackIcon: !_isTab,
              showLeftAvatar: false,
              showBorder: false,
              onBack: _goBack,
              backgroundColor: Colors.white,
            ),
            Expanded(
              child: ListView(
                children: [
                  // 顶部个人信息卡片
                  Obx(() => _buildUserCard()),
                  SizedBox(height: 10.w),
                  // 朋友圈、我的二维码
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildNavRow(
                          leading: Image.asset(
                            'lib/assets/images/moments.png',
                            width: 20.w,
                            height: 20.w,
                          ),
                          title: '朋友圈',
                          showBorder: true,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RoutePath.momentsUser,
                              arguments: {
                                'userId':
                                    _userController.userInfo.value?.userId ??
                                    '',
                                'nickname':
                                    _userController.userInfo.value?.nickname ??
                                    '',
                              },
                            );
                          },
                        ),
                        _buildNavRow(
                          leading: Icon(
                            MyIcon.myQrCode,
                            size: 20.w,
                            color: const Color.fromRGBO(0, 95, 255, 1),
                          ),
                          title: '我的二维码',
                          onTap: () =>
                              Navigator.pushNamed(context, RoutePath.myQRCode),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.w),
                  // 性别、个性签名、添加类型
                  Obx(
                    () => Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildNavRow(
                            title: '性别',
                            trailing: _buildValueText(_genderText),
                            showBorder: true,
                            onTap: () =>
                                Navigator.pushNamed(context, RoutePath.gender),
                          ),
                          _buildNavRow(
                            title: '个性签名',
                            trailing: _buildValueText(_personDescText),
                            showBorder: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              RoutePath.personDesc,
                            ),
                          ),
                          InkClick(
                            backgroundColor: Colors.white,
                            child: Container(
                              height: 60.w,
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '加我为朋友时需要验证',
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                  WeChatSwitch(
                                    value:
                                        (_userController
                                                .userInfo
                                                .value
                                                ?.joinType ??
                                            1) ==
                                        1,
                                    onChanged: _toggleJoinType,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10.w),
                  // 退出登录
                  _buildLogoutBtn(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
