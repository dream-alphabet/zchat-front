import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';
import 'package:zchat/widgets/wechat_switch.dart';

// 好友设置
class FriendSettingPage extends StatefulWidget {
  const FriendSettingPage({super.key});

  @override
  State<FriendSettingPage> createState() => _FriendSettingPageState();
}

class _FriendSettingPageState extends State<FriendSettingPage> {
  // 联系人id
  String _contactId = '';
  // 是否免打扰
  bool _disturb = false;
  // 联系人store
  final _userContactController = Get.find<UserContactController>();
  // 会话store
  final _sessionStore = Get.find<ChatSessionStore>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        // 接收路由参数
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        _initDisturb();
      }
    });
  }

  // 初始化免打扰状态
  Future<void> _initDisturb() async {
    // 优先从联系人store获取
    final contact = _userContactController.getUserContact(_contactId);
    if (contact != null) {
      _disturb = contact.disturb == DisturbStatusEnum.open;
      setState(() {});
      return;
    }
    // 联系人store没有，从接口获取
    final contactInfo = await getContactInfoApi(_contactId);
    if (contactInfo?.disturb != null) {
      _disturb = contactInfo!.disturb == DisturbStatusEnum.open;
      setState(() {});
    }
  }

  // 切换消息免打扰
  void _toggleDisturb(bool value) async {
    setState(() => _disturb = value);
    await updateContactSettingApi(
      UpdateContactSettingReq(
        contactId: _contactId,
        disturb: value ? DisturbStatusEnum.open : DisturbStatusEnum.close,
      ),
    );
    // 更新本地store
    _userContactController.updateContact(
      _contactId,
      disturb: value ? DisturbStatusEnum.open : DisturbStatusEnum.close,
    );
    // 同步会话列表的免打扰状态(用于红点角标)
    _sessionStore.updateDisturb(
      _contactId,
      value ? DisturbStatusEnum.open : DisturbStatusEnum.close,
    );
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
            _buildRow(
              showBorder: true,
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text('消息免打扰'),
                  WeChatSwitch(value: _disturb, onChanged: _toggleDisturb),
                ],
              ),
            ),
            _buildNavigateRow('朋友权限', RoutePath.friendAuthority),
          ],
        ),
      ),
    );
  }
}
