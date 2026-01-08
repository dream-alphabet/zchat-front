import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zchat/pages/auth/login.dart';
import 'package:zchat/pages/auth/register.dart';
import 'package:zchat/pages/main/main.dart';

// 路由配置
final Map<String, Widget Function(BuildContext)> routes = {
  '/': (ctx) => MainPage(),
  '/login': (ctx) => LoginPage(),
  '/register': (ctx) => RegisterPage()
};

// 全局Context
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey();

// 根组件
Widget getRootWidget() {
  // 响应式适配
  return ScreenUtilInit(
    // 设计稿尺寸
    designSize: Size(360, 640),
    // 是否根据宽度/高度中的最小值进行文本适配(防止字体在窄屏上过大)
    minTextAdapt: true,
    // 是否支持分屏模式(平板电脑)
    splitScreenMode: false,
    builder: (context, child) {
      return MaterialApp(
        title: 'zchat',
        // 设置主题中的文本样式也支持适配
        theme: ThemeData(
          fontFamily: 'Inter',
          textTheme: TextTheme(
            // 设置默认文本样式能自动响应字体缩放
            bodyMedium: TextStyle(fontSize: 16.sp),
          ),
          appBarTheme: AppBarTheme(
            surfaceTintColor: Colors.transparent,
          )
        ),
        navigatorKey: globalNavigatorKey,
        builder: FToastBuilder(),  // FToast轻提示构建器
        routes: routes,
        initialRoute: '/',
      );
    },
  );
}