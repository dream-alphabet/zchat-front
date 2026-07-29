import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 聊天信息
class ChatInfoPage extends StatefulWidget {
  const ChatInfoPage({super.key});

  @override
  State<ChatInfoPage> createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage> {
  // 构建cell行
  Widget _buildRow(Widget child, {GestureTapCallback? onTap}) {
    return InkClick(
      onTap: onTap,
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        padding: EdgeInsets.symmetric(vertical: 10.w),
        child: child,
      ),
    );
  }

  // 构建需要跳转页面的行
  Widget _buildNavigateRow(String text, String routePath) {
    return _buildRow(
      Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(text),
          Icon(
            MyIcon.arrowRight,
            size: 16.sp,
            color: Color.fromRGBO(174, 174, 174, 1),
          ),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, routePath);
      },
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
          statusBarColor: const Color.fromRGBO(237, 237, 237, 1),
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: const Color.fromRGBO(247, 247, 247, 1),
          // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '聊天信息',
              showLeftBackIcon: true,
              backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
              showRightIcon: false,
              showBorder: false,
            ),
            _buildNavigateRow('朋友设置', RoutePath.friendSetting),
            SizedBox(height: 10.w),
            _buildNavigateRow('查找聊天记录', RoutePath.friendSetting),
          ],
        ),
      ),
    );
  }
}
