import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/pages/chat/chat.dart';
import 'package:zchat/pages/contact/contact.dart';
import 'package:zchat/pages/share/share.dart';
import 'package:zchat/stores/token.dart';

// 主页
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 底部tab栏
  final List<_Tab> _tabs = [
    _Tab(
      icon: 'lib/assets/icon/chat.png',
      activeIcon: 'lib/assets/icon/chat_active.png',
      text: '聊天',
    ),
    _Tab(
      icon: 'lib/assets/icon/contact.png',
      activeIcon: 'lib/assets/icon/contact_active.png',
      text: '通讯录',
    ),
    _Tab(
      icon: 'lib/assets/icon/share.png',
      activeIcon: 'lib/assets/icon/share_active.png',
      text: '分享',
    ),
  ];
  // 要展示的页面列表
  final List<Widget> _pages = [ChatPage(), ContactPage(), SharePage()];
  // 当前激活的tab栏索引
  int _currentTabIndex = 0;

  // 构建底部导航栏项目
  List<BottomNavigationBarItem> _buildTabItems(BuildContext context) {
    return List.generate(
      _tabs.length,
      (index) => BottomNavigationBarItem(
        icon: Image.asset(_tabs[index].icon, width: 20.w, height: 20.w),
        activeIcon: Image.asset(
          _tabs[index].activeIcon,
          width: 20.w,
          height: 20.w,
        ),
        label: _tabs[index].text,
        backgroundColor: Colors.white,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 初始化toast
    ToastUtils.init();
    _initUser();
  }

  // 初始化用户信息
  Future<void> _initUser() async {
    // 初始化token管理器
    await tokenManager.init();
    final token = tokenManager.getToken();
    print('本地存储的token:$token');
    // 如果token为空，跳转到登录页面
    if(token.isEmpty) {
      // 关闭所有页面并跳转到登录页面
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    // TODO 获取用户信息并存入store
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      // 使用IndexedStack保持页面状态
      body: SafeArea(
        child: IndexedStack(index: _currentTabIndex, children: _pages),
      ),
      // 底部导航栏
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Color.fromRGBO(232, 232, 232, 1), width: 1.w),
          )
        ),
        child: Theme(
          // 禁用涟漪效果
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          child: BottomNavigationBar(
            enableFeedback: true,
            type: BottomNavigationBarType.fixed, // 固定样式，适合5个标签
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            currentIndex: _currentTabIndex,
            items: _buildTabItems(context),
            selectedItemColor: Colors.black,
            unselectedItemColor: Color.fromRGBO(122, 122, 122, 1),
            selectedFontSize: 12.sp,
            unselectedFontSize: 12.sp,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

// tab数据类
class _Tab {
  final String icon; // 正常显示的图标
  final String activeIcon; // 激活时的图标
  final String text; // tab标题

  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.text,
  });
}
