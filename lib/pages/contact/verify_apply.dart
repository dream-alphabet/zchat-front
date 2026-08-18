import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/widgets/page_header.dart';
import 'package:zchat/widgets/wechat_switch.dart';

// 验证联系人申请
class VerifyApplyPage extends StatefulWidget {
  const VerifyApplyPage({super.key});

  @override
  State<VerifyApplyPage> createState() => _VerifyApplyPageState();
}

class _VerifyApplyPageState extends State<VerifyApplyPage> {
  int _applyId = -1;
  // 申请类型(0:好友 1:群聊)
  int _contactType = UserContactTypeEnum.user;
  // 备注输入框控制器
  final _handleRemarkController = TextEditingController();
  // 是否仅聊天(仅好友申请有效)
  bool _onlyChat = false;

  // 是否好友申请
  bool get _isUserApply => _contactType == UserContactTypeEnum.user;

  @override
  void initState() {
    super.initState();
    // 接收联系人申请id参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _applyId = params['applyId'];
        _contactType = params['contactType'] ?? UserContactTypeEnum.user;
      }
    });
  }

  // 同意申请
  void agreeApply() async {
    // 备注
    final handleRemark = _handleRemarkController.text.trim();
    // 发送请求
    await handleApplyApi(
      HandleApplyReq(
        applyId: _applyId,
        status: ContactApplyStatusEnum.agree,
        handleRemark: _isUserApply && handleRemark.isNotEmpty ? handleRemark : null,
        handlePermission: _isUserApply
            ? (_onlyChat
                  ? ContactPermissionEnum.onlyChat
                  : ContactPermissionEnum.allowMoments)
            : null,
      ),
    );
    ToastUtils.showGlobalToast(msg: '已同意');
    Navigator.pop(context, ContactApplyStatusEnum.agree);
  }

  // 拒绝申请
  void rejectApply() async {
    // 发送请求
    await handleApplyApi(
      HandleApplyReq(
        applyId: _applyId,
        status: ContactApplyStatusEnum.reject,
        handleRemark: null,
        handlePermission: null,
      ),
    );
    ToastUtils.showGlobalToast(msg: '已拒绝');
    Navigator.pop(context, ContactApplyStatusEnum.reject);
  }

  // 备注输入框(仅好友申请)
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
            controller: _handleRemarkController,
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
      margin: EdgeInsetsGeometry.symmetric(horizontal: 15.w),
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

  // 操作按钮
  Widget _buildBtn() {
    return Column(
      spacing: 10.w,
      children: [
        GestureDetector(
          onTap: agreeApply,
          child: Container(
            width: 100.w,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(20, 134, 237, 1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 12.w),
            alignment: Alignment.center,
            child: Text(
              '同意',
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
            ),
          ),
        ),
        GestureDetector(
          onTap: rejectApply,
          child: Container(
            width: 100.w,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(247, 247, 247, 1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 12.w),
            alignment: Alignment.center,
            child: Text(
              '拒绝',
              style: TextStyle(fontSize: 16.sp, color: Colors.black),
            ),
          ),
        ),
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
          systemNavigationBarColor: Colors.white, // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            spacing: 20.w,
            children: [
              PageHeader(
                title: '验证好友申请',
                showBorder: false,
                showRightIcon: false,
                showLeftBackIcon: true,
                backgroundColor: Colors.white,
              ),
              if (_isUserApply) ...[
                _buildRemark(),
                _buildPermission(),
              ],
              SizedBox(height: 10.w),
              _buildBtn(),
            ],
          ),
        ),
      ),
    );
  }
}
