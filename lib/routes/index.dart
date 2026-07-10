import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zchat/common/animation.dart';
import 'package:zchat/pages/auth/login.dart';
import 'package:zchat/pages/auth/register.dart';
import 'package:zchat/pages/chat/message.dart';
import 'package:zchat/pages/chat/video_call.dart';
import 'package:zchat/pages/chat/voice_call.dart';
import 'package:zchat/pages/contact/add_contact.dart';
import 'package:zchat/pages/contact/add_friend.dart';
import 'package:zchat/pages/contact/contact_select.dart';
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
import 'package:zchat/pages/my/my.dart';
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
  RoutePath.my: (ctx) => MyPage(),
  RoutePath.friendSetting: (ctx) => FriendSettingPage(),
  RoutePath.addContact: (ctx) => AddContactPage(),
  RoutePath.verifyApply: (ctx) => VerifyApplyPage(),
  RoutePath.chatMessage: (ctx) => ChatMessagePage(),
  RoutePath.groupSetting: (ctx) => GroupSettingPage(),
  RoutePath.videoCall: (ctx) => VideoCallPage(),
  RoutePath.voiceCall: (ctx) => VoiceCallPage(),
  RoutePath.contactSelect: (ctx) => ContactSelectPage(),
};

// 全局Context
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey();
// 观察者实例
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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
        navigatorObservers: [routeObserver],
        title: 'zchat',
        // 设置主题中的文本样式也支持适配
        theme: ThemeData(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: Colors.blue,
            selectionHandleColor: Colors.orange,
            cursorColor: Color.fromRGBO(20, 134, 237, 1),
          ),
          textTheme: TextTheme(
            // 设置默认文本样式能自动响应字体缩放
            // 字体回退链：正文使用Inter渲染，emoji使用NotoColorEmoji渲染
            bodyMedium: TextStyle(
              fontFamily: 'MyInter',
              fontFamilyFallback: ['MyEmoji'],
              fontSize: 16.sp,
            ),
          ),
          appBarTheme: AppBarTheme(surfaceTintColor: Colors.transparent),
          // 配置页面过渡主题: android和ios都配置为ios的滑动效果
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        navigatorKey: globalNavigatorKey,
        builder: FToastBuilder(), // FToast轻提示构建器
        initialRoute: RoutePath.main,
        onGenerateRoute: (settings) {
          // 根据路由名获取对应的 WidgetBuilder
          final builder = routes[settings.name];
          if (builder == null) {
            return null;
          }
          // 联系人选择页面使用SlideUp动画
          if (settings.name == RoutePath.contactSelect) {
            return RouteUtils.slideUp(builder, settings: settings);
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
        // 语言设置
        locale: Locale('zh'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // 支持的语言
        supportedLocales: [
          //此处设置
          Locale('zh', 'CH'),
          Locale('en', 'US'),
        ],
      );
    },
  );
}
