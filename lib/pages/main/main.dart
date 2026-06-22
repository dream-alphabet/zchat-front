import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/common/websocket.dart';
import 'package:zchat/pages/chat/chat.dart';
import 'package:zchat/pages/contact/contact.dart';
import 'package:zchat/pages/discover/discover.dart';
import 'package:zchat/pages/my/my.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/message.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/stores/token.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/badge.dart';

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
      icon: 'lib/assets/icon/discover.png',
      activeIcon: 'lib/assets/icon/discover_active.png',
      text: '发现',
    ),
  ];
  // 当前激活的tab栏索引
  int _currentTabIndex = 1;
  // PageView控制器
  final _pageController = PageController(initialPage: 1);
  // 用户信息store
  final _userController = Get.put(UserController());
  // 联系人store
  final _userContactController = Get.put(UserContactController());
  // 聊天会话store
  final _chatSessionStore = Get.put(ChatSessionStore());
  // 消息store
  final _messageStore = Get.put(MessageController());

  // 获取徽标数量(未读消息数)
  int _getUnreadCount(int index) {
    final tab = _tabs[index].text;
    if (tab == '聊天') {
      return _messageStore.chatUnreadTotal.value;
    } else if (tab == '通讯录') {
      return _messageStore.contactUnreadTotal.value;
    } else if (tab == '发现') {
      return _messageStore.discoverUnreadTotal.value;
    }
    return 0;
  }

  // 构建底部导航栏项目
  List<BottomNavigationBarItem> _buildTabItems() {
    return List.generate(_tabs.length, (index) {
      int unreadCount = _getUnreadCount(index);
      return BottomNavigationBarItem(
        icon: UnreadCountBadge(
          count: unreadCount,
          child: Image.asset(_tabs[index].icon, width: 20.w, height: 20.w),
        ),
        activeIcon: UnreadCountBadge(
          count: unreadCount,
          child: Image.asset(
            _tabs[index].activeIcon,
            width: 20.w,
            height: 20.w,
          ),
        ),
        label: _tabs[index].text,
        backgroundColor: Colors.white,
      );
    });
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
    if (token.isEmpty) {
      // 关闭所有页面并跳转到登录页面
      Navigator.pushNamedAndRemoveUntil(
        context,
        RoutePath.login,
        (route) => false,
      );
      return;
    }
    // 获取用户信息并存入store
    _userController.getUserInfo();
    // 获取联系人信息
    _userContactController.getUserContactList();
    // 获取群聊列表
    _userContactController.getGroupList();
    // 获取会话列表
    _chatSessionStore.getSessionList();
    initWebSocket();
    await requestNotificationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Color.fromRGBO(247, 247, 247, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color.fromRGBO(247, 247, 247, 1), // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color.fromRGBO(
            247,
            247,
            247,
            1,
          ), // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Color.fromRGBO(247, 247, 247, 1),
      // 使用IndexedStack保持页面状态
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          // 左右滑动切换时，更新index
          onPageChanged: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          physics: ClampingScrollPhysics(),
          children: [
            MyPage(
              onBack: () {
                _pageController.animateToPage(
                  1,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
                setState(() {
                  _currentTabIndex = 1;
                });
              },
            ),
            ChatPage(),
            ContactPage(),
            DiscoverPage(),
          ],
        ),
      ),
      // 底部导航栏(如果是个人中心页面，不显示底部导航栏)
      bottomNavigationBar: _currentTabIndex > 0
          ? Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color.fromRGBO(232, 232, 232, 1),
                    width: 1.w,
                  ),
                ),
              ),
              child: Theme(
                // 禁用涟漪效果
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Obx(
                  () => BottomNavigationBar(
                    enableFeedback: true,
                    type: BottomNavigationBarType.fixed, // 固定样式，适合5个标签
                    onTap: (index) {
                      // 带动画地切换页面
                      _pageController.animateToPage(
                        index+1,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                      // 更新index
                      setState(() {
                        _currentTabIndex = index+1;
                      });
                    },
                    currentIndex: _currentTabIndex - 1,
                    items: _buildTabItems(),
                    selectedItemColor: Colors.black,
                    unselectedItemColor: Color.fromRGBO(122, 122, 122, 1),
                    selectedFontSize: 12.sp,
                    unselectedFontSize: 12.sp,
                    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Color.fromRGBO(247, 247, 247, 1),
                  ),
                ),
              ),
            )
          : SizedBox(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
