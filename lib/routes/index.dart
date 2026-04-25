import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zchat/pages/auth/login.dart';
import 'package:zchat/pages/auth/register.dart';
import 'package:zchat/pages/chat/message.dart';
import 'package:zchat/pages/chat/video_call.dart';
import 'package:zchat/pages/chat/voice_call.dart';
import 'package:zchat/pages/contact/add_contact.dart';
import 'package:zchat/pages/contact/add_friend.dart';
import 'package:zchat/pages/contact/create_group.dart';
import 'package:zchat/pages/contact/friend_setting.dart';
import 'package:zchat/pages/contact/group_chat.dart';
import 'package:zchat/pages/contact/group_setting.dart';
import 'package:zchat/pages/contact/new_friend.dart';
import 'package:zchat/pages/contact/only_chat_friend.dart';
import 'package:zchat/pages/contact/search_contact.dart';
import 'package:zchat/pages/contact/contact_info.dart';
import 'package:zchat/pages/contact/verify_apply.dart';
import 'package:zchat/pages/discover/moments.dart';
import 'package:zchat/pages/discover/scan.dart';
import 'package:zchat/pages/main/main.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/pages/my/my_qrcode.dart';

// 路由配置
final Map<String, WidgetBuilder> routes = {
  RoutePath.main: (ctx) => MainPage(),
  RoutePath.login: (ctx) => LoginPage(),
  RoutePath.register: (ctx) => RegisterPage(),
  RoutePath.newFriend: (ctx) => NewFriendPage(),
  RoutePath.onlyChatFriend: (ctx) => OnlyChatFriendPage(),
  RoutePath.groupChat: (ctx) => GroupChatPage(),
  RoutePath.contactInfo: (ctx) => ContactInfoPage(),
  RoutePath.moments: (ctx) => MomentsPage(),
  RoutePath.scan: (ctx) => ScanPage(),
  RoutePath.addFriend: (ctx) => AddFriendPage(),
  RoutePath.createGroup: (ctx) => CreateGroupPage(),
  RoutePath.searchContact: (ctx) => SearchContactPage(),
  RoutePath.myQRCode: (ctx) => MyQrcodePage(),
  RoutePath.friendSetting: (ctx) => FriendSettingPage(),
  RoutePath.addContact: (ctx) => AddContactPage(),
  RoutePath.verifyApply: (ctx) => VerifyApplyPage(),
  RoutePath.chatMessage: (ctx) => ChatMessagePage(),
  RoutePath.groupSetting: (ctx) => GroupSettingPage(),
  RoutePath.videoCall: (ctx) => VideoCallPage(),
  RoutePath.voiceCall: (ctx) => VoiceCallPage()
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
        // 隐藏调试时右上角显示的debug banner
        debugShowCheckedModeBanner: false,
        title: 'zchat',
        // 设置主题中的文本样式也支持适配
        theme: ThemeData(
          fontFamily: 'Inter',
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: Color.fromRGBO(20, 134, 237, 1),
            selectionHandleColor: Color.fromRGBO(20, 134, 237, 1),
            cursorColor: Color.fromRGBO(20, 134, 237, 1),
          ),
          textTheme: TextTheme(
            // 设置默认文本样式能自动响应字体缩放
            bodyMedium: TextStyle(fontSize: 16.sp),
          ),
          appBarTheme: AppBarTheme(surfaceTintColor: Colors.transparent),
          // 配置页面过渡主题
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              // Android 缩放效果
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              // iOS 滑动效果
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        navigatorKey: globalNavigatorKey,
        builder: FToastBuilder(), // FToast轻提示构建器
        routes: routes,
        initialRoute: RoutePath.main,
        // 语言设置
        locale: Locale('zh'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          //此处设置
          Locale('zh', 'CH'),
          Locale('en', 'US'),
        ],
      );
    },
  );
}
