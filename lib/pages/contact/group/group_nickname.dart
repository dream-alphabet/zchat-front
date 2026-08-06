import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/page_header.dart';

// 我在群里的昵称
class GroupNicknamePage extends StatefulWidget {
  const GroupNicknamePage({super.key});

  @override
  State<GroupNicknamePage> createState() => _GroupNicknamePageState();
}

class _GroupNicknamePageState extends State<GroupNicknamePage> {
  // 群聊信息
  String _groupId = '';

  // 群聊昵称输入框控制器
  final _groupNicknameController = TextEditingController();

  // 群聊昵称
  String _groupNickname = '';

  // 群聊昵称是否为空
  bool get _isGroupNicknameEmpty => _groupNickname.trim().isEmpty;

  // 联系人store
  final _userContactController = Get.find<UserContactController>();

  // 用户store
  final _userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    // 接收路由参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        setState(() {
          _groupId = params['groupId'];
          final contact = _userContactController.findUserContact(
            _groupId,
            UserContactTypeEnum.group,
          );
          if (contact != null) {
            _groupNickname =
                contact.groupNickname ??
                _userController.userInfo.value!.nickname;
            _groupNicknameController.text = _groupNickname;
          }
        });
      }
    });
  }

  // 修改群昵称
  void _updateGroupNickname() async {
    if (_isGroupNicknameEmpty) {
      ToastUtils.showGlobalToast(msg: '群昵称不能为空');
      return;
    }
    await updateContactSettingApi(
      UpdateContactSettingReq(
        contactId: _groupId,
        groupNickname: _groupNickname,
      ),
    );
    // 更新本地store的群昵称
    _userContactController.updateContact(
      _groupId,
      groupNickname: _groupNickname,
    );
    ToastUtils.showGlobalToastAsync(msg: '更新成功').whenComplete(() {
      Navigator.pop(context);
    });
  }

  // 构建提示
  Widget _buildNotice() {
    return Column(
      spacing: 10.w,
      children: [
        Text('我在群里的昵称', style: TextStyle(fontSize: 20.sp)),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w),
          child: Text('昵称修改后，只会在群内显示，群内成员都可以看见。', textAlign: .center),
        ),
      ],
    );
  }

  // 构建输入框
  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.w),
      child: Row(
        crossAxisAlignment: .center,
        spacing: 10.w,
        children: [
          ContactAvatar(contactId: _groupId, shape: .rectangle),
          Expanded(
            child: TextField(
              controller: _groupNicknameController,
              onChanged: (value) {
                _groupNickname = value;
              },
              textInputAction: .done,
              maxLength: 20,
              maxLines: 1,
              // 隐藏计数文本
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => const SizedBox.shrink(),
              decoration: InputDecoration(
                hintText: '请输入昵称',
                hintStyle: TextStyle(color: Color.fromRGBO(174, 174, 174, 1)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 完成按钮
  Widget _buildFinishBtn() {
    return GestureDetector(
      onTap: _updateGroupNickname,
      child: Container(
        width: 100.w,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 134, 237, 1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.w),
        alignment: Alignment.center,
        child: Text(
          '完成',
          style: TextStyle(fontSize: 16.sp, color: Colors.white),
        ),
      ),
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
          statusBarColor: Colors.white, // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white, // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '',
              showLeftBackIcon: true,
              showBorder: false,
              backgroundColor: Colors.white,
              showRightIcon: false,
            ),
            SizedBox(height: 40.w),
            _buildNotice(),
            SizedBox(height: 10.w),
            _buildInput(),
            Expanded(child: SizedBox()),
            SizedBox(height: 20.w),
            _buildFinishBtn(),
            SizedBox(height: 20.w),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNicknameController.dispose();
    super.dispose();
  }
}
