import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/common.dart';
import 'package:zchat/model/group.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/dialog.dart';
import 'package:zchat/widgets/page_header.dart';
import 'package:zchat/widgets/qrcode.dart';

// 群二维码
class GroupQrcodePage extends StatefulWidget {
  const GroupQrcodePage({super.key});

  @override
  State<GroupQrcodePage> createState() => _GroupQrcodePageState();
}

class _GroupQrcodePageState extends State<GroupQrcodePage> {
  // 群聊信息
  Group? _group;

  // 二维码key
  final _qrcodeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 接收路由参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        setState(() {
          _group = params['group'];
        });
      }
    });
  }

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

  // 构建群聊二维码
  Widget _buildQrCode() {
    // 二维码数据
    final data = QrCodeData(
      type: QrCodeType.person.type,
      data: _group?.groupId ?? '',
    );
    return RepaintBoundary(
      key: _qrcodeKey,
      child: Container(
        color: Colors.white,
        child: Qrcode(data: jsonEncode(data.toJson()), size: 250),
      ),
    );
  }

  // 构建主要内容
  Widget _buildMain() {
    return Column(
      children: [
        ContactAvatar(contactId: _group?.groupId ?? '', shape: .rectangle),
        SizedBox(height: 10.w),
        Text('群聊：${_group?.groupName}', style: TextStyle(fontSize: 18.sp)),
        SizedBox(height: 20.w),
        _buildQrCode(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white, // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white, // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: .spaceBetween,
          children: [
            PageHeader(
              title: '',
              showLeftBackIcon: true,
              showBorder: false,
              backgroundColor: Colors.white,
              showRightIcon: false,
            ),
            _buildMain(),
            Padding(
              padding: EdgeInsetsGeometry.only(bottom: 20.w),
              child: GestureDetector(
                onTap: _saveToGallery,
                child: Text(
                  '保存图片',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Color.fromRGBO(83, 106, 149, 1),
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
