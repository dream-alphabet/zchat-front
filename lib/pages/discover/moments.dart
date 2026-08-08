import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/page_header.dart';

// 朋友圈
class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  // 用户store
  final _userController = Get.find<UserController>();

  // 滚动控制器
  final _scrollController = ScrollController();

  // 顶部是否可见
  bool _isTopVisible = true;

  // 顶部区域高度
  final _topHeight = 300.w;

  // 顶部状态栏和header的图标颜色
  Color get _topIconColor => _isTopVisible ? Colors.white : Colors.black;

  // 顶部状态栏背景颜色
  Color get _topColor => _isTopVisible
      ? Color.fromRGBO(87, 87, 87, 1)
      : Color.fromRGBO(227, 227, 227, 1);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  // 滚动事件
  void _onScroll() {
    // 监听顶部区域是否还在屏幕
    final bool visible = _scrollController.offset < _topHeight;
    if (visible != _isTopVisible) {
      setState(() {
        _isTopVisible = visible;
      });
    }
  }

  // 构建顶部区域
  Widget _buildTop() {
    return Stack(
      clipBehavior: .none,
      children: [
        Container(
          width: double.infinity,
          height: _topHeight,
          decoration: BoxDecoration(
            color: Color.fromRGBO(87, 87, 87, 1),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(87, 87, 87, 1),
                Colors.black.withOpacity(0.8),
              ],
              stops: [0.9, 1.0], // 仅在底部 20% 区域出现阴影
            ),
          ),
          alignment: .center,
          child: Text(
            '轻触更换封面',
            style: TextStyle(
              fontSize: 14.sp,
              color: Color.fromRGBO(134, 134, 134, 1),
            ),
          ),
        ),
        Positioned(
          right: 80.w,
          bottom: 2.w,
          child: Text(
            _userController.userInfo.value?.nickname ?? '',
            style: TextStyle(fontSize: 20.sp, color: Colors.white),
          ),
        ),
        Positioned(
          right: 10.w,
          bottom: -20.w,
          child: ContactAvatar(
            contactId: _userController.userInfo.value?.userId ?? '-1',
            size: 60,
            shape: .rectangle,
          ),
        ),
      ],
    );
  }

  // 构建页面头部
  Widget _buildPageHeader() {
    return PageHeader(
      title: _isTopVisible ? '' : '朋友圈',
      showLeftBackIcon: true,
      showRightIcon: true,
      backgroundColor: _isTopVisible
          ? Colors.transparent
          : Color.fromRGBO(227, 227, 227, 1),
      showBorder: false,
      iconColor: _topIconColor,
      rightIconList: [
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RoutePath.momentsPublish);
          },
          child: Icon(Icons.add, size: 24.sp, color: _topIconColor),
        ),
      ],
    );
  }

  // 主要内容
  Widget _buildMain() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: 100,
      itemBuilder: (ctx, index) {
        if (index == 0) {
          return _buildTop();
        }
        return Container(
          width: double.infinity,
          height: 50.w,
          alignment: .center,
          child: Text('$index'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: _topColor,
        bottomOpacity: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarBrightness: _isTopVisible
              ? Brightness.dark
              : Brightness.light,
          statusBarIconBrightness: _isTopVisible
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(children: [_buildMain(), _buildPageHeader()]),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
