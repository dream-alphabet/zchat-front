import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/model/enums/group.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/dialog.dart';
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
      ToastUtils.showGlobalToast(msg: '用户/群聊不存在');
      Navigator.pop(context);
      return;
    }
    // 群聊状态为已解散
    if (contactInfo.contactType == UserContactTypeEnum.group &&
        contactInfo.groupStatus == GroupStatusEnum.dissolve) {
      await showPromptDialog(context, '群聊已解散');
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
          // 跳转到聊天信息页面(只有好友有)
          if (_contactInfo?.contactType == UserContactTypeEnum.user &&
              _contactInfo?.contactStatus == UserContactStatusEnum.friend)
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RoutePath.chatInfo,
                  arguments: {'contactId': _contactId},
                );
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
          ContactAvatar(contactId: _contactId, size: 50),
          Expanded(
            child: Text(
              _contactInfo?.contactName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 性别显示文案
  String get _genderText {
    // 机器人没有性别概念
    if (_contactId == GlobalConstants.robotContactId) {
      return '未知';
    }
    final gender = _contactInfo?.gender;
    if (gender == null) {
      return '未设置';
    }
    return gender == 1 ? '男' : '女';
  }

  // 签名显示文案
  String get _personDescText {
    final desc = _contactInfo?.personDesc;
    if (desc == null || desc.isEmpty) {
      return '未填写';
    }
    return desc;
  }

  // 好友信息行(标题+值)
  Widget _buildInfoRow(String title, String value, {GestureTapCallback? onTap}) {
    return InkClick(
      onTap: onTap,
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color.fromRGBO(237, 237, 237, 1),
              width: 1.w,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(title, style: TextStyle(fontSize: 16.sp)),
            SizedBox(width: 15.w),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color.fromRGBO(174, 174, 174, 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 好友信息卡(性别/个性签名, 仅好友显示)
  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _buildInfoRow('性别', _genderText),
          // 签名过长省略，点击查看完整文本
          _buildInfoRow('个性签名', _personDescText, onTap: _showPersonDescDialog),
        ],
      ),
    );
  }

  // 查看完整个性签名
  void _showPersonDescDialog() {
    final desc = _personDescText;
    if (desc == '未填写') {
      return;
    }
    showContentDialog(context, title: '个性签名', content: desc);
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
            color: const Color.fromRGBO(20, 134, 237, 1),
          ),
        ),
      ),
    );
  }

  // 是否显示朋友圈入口(自己或好友)
  bool _showMomentsEntry() {
    final contactInfo = _contactInfo;
    if (contactInfo == null) return false;
    // 自己
    if (_contactId == _userController.userInfo.value?.userId) return true;
    // 好友
    if (contactInfo.contactStatus != UserContactStatusEnum.friend) return false;
    // 对方设置了我仅聊天，隐藏朋友圈入口
    if (contactInfo.canViewMoments == false) return false;
    return true;
  }

  // 构建朋友圈入口
  Widget _buildMomentsEntry() {
    return InkClick(
      onTap: () {
        Navigator.pushNamed(
          context,
          RoutePath.momentsUser,
          arguments: {
            'userId': _contactId,
            'nickname': _contactInfo?.contactName ?? '',
          },
        );
      },
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
        child: Row(
          spacing: 10.w,
          children: [
            Icon(Icons.photo_library_outlined, size: 22.w, color: Colors.black),
            Text('朋友圈', style: TextStyle(fontSize: 16.sp)),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20.w,
              color: Color.fromRGBO(199, 199, 204, 1),
            ),
          ],
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
        style: TextStyle(
          fontSize: 18.sp,
          color: const Color.fromRGBO(97, 97, 97, 1),
        ),
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
          _buildBottomBtn('添加到通讯录', () async {
            final joinType = await Navigator.pushNamed(
              context,
              RoutePath.addContact,
              arguments: {
                'contactId': _contactId,
                'contactType': _contactInfo?.contactType,
              },
            );
            // 如果联系人添加类型是直接添加，重新获取联系人信息
            if (joinType == JoinTypeEnum.directAdd) {
              _getContactInfo();
            }
          }),
        if (_contactInfo?.contactStatus == UserContactStatusEnum.friend)
          _buildBottomBtn('发消息', () {
            Navigator.pushNamed(
              context,
              RoutePath.chatMessage,
              arguments: {
                'contactId': _contactInfo?.contactId,
                'contactType': _contactInfo?.contactType,
                'sessionId': _contactInfo?.sessionId,
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
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTop(),
            _buildCenter(),
            if (_contactInfo?.contactType == UserContactTypeEnum.user &&
                _contactInfo?.contactStatus == UserContactStatusEnum.friend)
              _buildUserInfoCard(),
            if (_showMomentsEntry()) _buildMomentsEntry(),
            SizedBox(height: 20.w),
            _contactId != _userController.userInfo.value?.userId
                ? _buildBottom()
                : _buildWarn('不能和自己添加好友'),
          ],
        ),
      ),
    );
  }
}
