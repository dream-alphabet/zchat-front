import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/page_header.dart';
import 'package:zchat/widgets/wechat_switch.dart';

// 添加到通讯录
class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  // 用户信息store
  final _userController = Get.find<UserController>();
  // 打招呼内容输入框控制器
  final _applyInfoController = TextEditingController();
  // 备注输入框控制器
  final _applyRemarkController = TextEditingController();
  // 联系人id
  String _contactId = '';
  // 联系人类型(0:好友 1:群聊)
  int _contactType = UserContactTypeEnum.user;
  // 是否仅聊天(仅好友申请有效)
  bool _onlyChat = false;

  // 是否好友申请(群聊申请没有备注和权限一说)
  bool get _isUserApply => _contactType == UserContactTypeEnum.user;

  @override
  void initState() {
    super.initState();
    // 接收联系人id参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        _contactType = params['contactType'] ?? UserContactTypeEnum.user;
      }
    });
    // 设置默认文本
    _applyInfoController.text = '我是${_userController.userInfo.value!.nickname}';
  }

  // 发送添加朋友申请
  void _send() async {
    // 打招呼内容
    final applyInfo = _applyInfoController.text;
    if (applyInfo.isEmpty) {
      ToastUtils.showGlobalToast(msg: '打招呼内容不能为空');
      return;
    }
    // 备注
    final applyRemark = _applyRemarkController.text.trim();
    // 请求接口，返回联系人加入类型
    int joinType = await sendContactApplyApi(
      SendApplyReq(
        contactId: _contactId,
        applyInfo: applyInfo,
        applyRemark: _isUserApply && applyRemark.isNotEmpty ? applyRemark : null,
        applyPermission: _isUserApply
            ? (_onlyChat
                  ? ContactPermissionEnum.onlyChat
                  : ContactPermissionEnum.allowMoments)
            : null,
      ),
    );
    if (joinType == JoinTypeEnum.directAdd) {
      ToastUtils.showGlobalToast(msg: '添加成功');
    } else {
      ToastUtils.showGlobalToast(msg: '发送成功');
    }
    Navigator.pop(context, joinType);
  }

  // 打招呼内容
  Widget _buildApplyInfo() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 30.w, vertical: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.w,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(left: 15.w),
            child: Text(
              '打招呼内容',
              style: TextStyle(color: const Color.fromRGBO(108, 109, 109, 1)),
            ),
          ),
          TextField(
            controller: _applyInfoController,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: Colors.black, fontSize: 16.sp),
            maxLength: 50,
            maxLines: 3,
            // 去掉计数文本
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => const SizedBox.shrink(),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromRGBO(247, 247, 247, 1),
              hintText: '打个招呼吧...',
              hintStyle: TextStyle(
                color: const Color.fromRGBO(178, 178, 178, 1),
                fontSize: 16.sp,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15.w,
                vertical: 12.w,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 备注(仅好友申请)
  Widget _buildRemark() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 30.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.w,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(left: 15.w),
            child: Text(
              '备注',
              style: TextStyle(color: const Color.fromRGBO(108, 109, 109, 1)),
            ),
          ),
          TextField(
            controller: _applyRemarkController,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: Colors.black, fontSize: 16.sp),
            maxLength: 20,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromRGBO(247, 247, 247, 1),
              hintText: '给朋友设置备注',
              hintStyle: TextStyle(
                color: const Color.fromRGBO(178, 178, 178, 1),
                fontSize: 16.sp,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15.w,
                vertical: 12.w,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 仅聊天开关(仅好友申请)
  Widget _buildPermission() {
    return Container(
      width: double.infinity,
      margin: EdgeInsetsGeometry.only(top: 20.w, left: 15.w, right: 15.w),
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 15.w),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text('仅聊天', style: TextStyle(fontSize: 16.sp)),
                WeChatSwitch(
                  value: _onlyChat,
                  onChanged: (value) {
                    setState(() => _onlyChat = value);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(15.w, 0, 15.w, 15.w),
            child: Text(
              '仅聊天时，对方只能查看你的聊天记录，不能查看你的朋友圈等',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color.fromRGBO(174, 174, 174, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 发送按钮
  Widget _buildSendBtn() {
    return GestureDetector(
      onTap: _send,
      child: Container(
        width: 100.w,
        padding: EdgeInsets.symmetric(vertical: 12.w),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 134, 237, 1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        alignment: Alignment.center,
        child: Text(
          '发送',
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
          statusBarColor: Colors.white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white, // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              PageHeader(
                title: '申请添加朋友',
                showLeftBackIcon: true,
                showRightIcon: false,
                showBorder: false,
                backgroundColor: Colors.white,
              ),
              _buildApplyInfo(),
              if (_isUserApply) ...[
                _buildRemark(),
                _buildPermission(),
              ],
              SizedBox(height: 50.w),
              _buildSendBtn()
            ],
          ),
        ),
      ),
    );
  }
}
