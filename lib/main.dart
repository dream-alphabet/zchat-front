import 'package:flutter/material.dart';
import 'package:zchat/common/notification_helper.dart';
import 'package:zchat/routes/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  // 确保 WidgetsBinding 已初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化 ScreenUtil，必须在 runApp 之前
  ScreenUtil.ensureScreenSize();
  // 初始化通知栏工具类
  final helper = NotificationHelper();
  await helper.initialize();
  runApp(getRootWidget());
}
