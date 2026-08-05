import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 好友设置
class FriendSettingPage extends StatefulWidget {
  const FriendSettingPage({super.key});

  @override
  State<FriendSettingPage> createState() => _FriendSettingPageState();
}

class _FriendSettingPageState extends State<FriendSettingPage> {
  // 联系人id
  String _contactId = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        // 接收路由参数
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
      }
    });
  }

  // 构建cell行
  Widget _buildRow(
    Widget child, {
    GestureTapCallback? onTap,
    bool showBorder = false,
  }) {
    return InkClick(
      onTap: onTap,
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        padding: EdgeInsets.symmetric(vertical: 10.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: showBorder
                ? BorderSide(
                    width: 1.w,
                    color: Color.fromRGBO(237, 237, 237, 1),
                  )
                : .none,
          ),
        ),
        child: child,
      ),
    );
  }

  // 构建需要跳转页面的行
  Widget _buildNavigateRow(
    String text,
    String routePath, {
    bool showBorder = false,
  }) {
    return _buildRow(
      showBorder: showBorder,
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
        Navigator.pushNamed(
          context,
          routePath,
          arguments: {'contactId': _contactId},
        );
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
          systemNavigationBarColor: const Color.fromRGBO(237, 237, 237, 1),
          // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '朋友设置',
              showLeftBackIcon: true,
              backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
              showRightIcon: false,
              showBorder: false,
            ),
            _buildNavigateRow('备注', RoutePath.friendRemark, showBorder: true),
            _buildNavigateRow('朋友权限', RoutePath.friendAuthority),
          ],
        ),
      ),
    );
  }
}
