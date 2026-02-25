import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/ink_click.dart';

// 联系人信息(用户/群聊)
class ContactInfoPage extends StatefulWidget {
  const ContactInfoPage({super.key});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  // 联系人id(用户/群聊)
  String _contactId = '';
  // 联系人信息
  ContactInfoRes? _contactInfo;
  // 用户信息store
  final _userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    // 接收联系人id参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        _getContactInfo();
      }
    });
  }

  // 获取联系人信息
  Future<void> _getContactInfo() async {
    final contactInfo = await getContactInfoApi(_contactId);
    // 结果为空
    if (contactInfo == null) {
      ToastUtils.showGlobalToast(msg: '没有查询到该联系人信息');
      Navigator.pop(context);
      return;
    }
    _contactInfo = contactInfo;
    setState(() {});
  }

  // 构建顶部操作区域
  Widget _buildTop() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 15.w,
        vertical: 20.w,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios, size: 20.w, color: Colors.black),
          ),
          // 好友设置(只有好友有)
          if (_contactInfo?.contactType == UserContactTypeEnum.user)
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, RoutePath.friendSetting);
              },
              child: Icon(
                Icons.more_horiz_rounded,
                size: 25.w,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  // 构建中间信息
  Widget _buildCenter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(start: 15.w, bottom: 20.w),
      color: Colors.white,
      child: Row(
        spacing: 20.w,
        children: [
          ContactAvatar(imageUrl: 'lib/assets/test/01.png', size: 50),
          Text(_contactInfo?.contactName ?? ''),
        ],
      ),
    );
  }

  // 底部操作按钮
  Widget _buildBottomBtn(String name, GestureTapCallback onTap) {
    return InkClick(
      onTap: onTap,
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
        alignment: Alignment.center,
        child: Text(
          name,
          style: TextStyle(
            fontSize: 18.sp,
            color: Color.fromRGBO(20, 134, 237, 1),
          ),
        ),
      ),
    );
  }

  // 底部提示
  Widget _buildWarn(String info) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
      alignment: Alignment.center,
      color: Colors.white,
      child: Text(
        info,
        style: TextStyle(fontSize: 18.sp, color: Color.fromRGBO(97, 97, 97, 1)),
      ),
    );
  }

  // 是否可以添加到通讯录
  bool _canAdd() {
    // 已经是好友或者处于拉黑状态不能添加
    return ![
      UserContactStatusEnum.friend,
      UserContactStatusEnum.block,
      UserContactStatusEnum.beBlocked,
    ].contains(_contactInfo?.contactStatus);
  }

  // 是否处于拉黑状态
  bool _isBlocked() {
    return [
      UserContactStatusEnum.block,
      UserContactStatusEnum.beBlocked,
    ].contains(_contactInfo?.contactStatus);
  }

  // 构建底部操作区域
  Widget _buildBottom() {
    return Column(
      children: [
        if (_canAdd())
          _buildBottomBtn('添加到通讯录', () {
            Navigator.pushNamed(
              context,
              RoutePath.addContact,
              arguments: {'contactId': _contactId},
            );
          }),
        if (_contactInfo?.contactStatus == UserContactStatusEnum.friend)
          _buildBottomBtn('发消息', () {
            Navigator.pushNamed(
              context,
              RoutePath.chatMessage,
              arguments: {
                'contactId': _contactInfo?.contactId,
                'contactType': _contactInfo?.contactType,
              },
            );
          }),
        if (_isBlocked()) _buildWarn('已拉黑'),
      ],
    );
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
          systemNavigationBarColor: Colors.transparent, // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTop(),
            _buildCenter(),
            SizedBox(height: 20.w),
            _contactId != _userController.getUserInfo()?.userId
                ? _buildBottom()
                : _buildWarn('不能和自己添加好友'),
          ],
        ),
      ),
    );
  }
}
