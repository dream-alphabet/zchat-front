import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/widgets/page_header.dart';

// 验证联系人申请
class VerifyApplyPage extends StatefulWidget {
  const VerifyApplyPage({super.key});

  @override
  State<VerifyApplyPage> createState() => _VerifyApplyPageState();
}

class _VerifyApplyPageState extends State<VerifyApplyPage> {
  int _applyId = -1;

  @override
  void initState() {
    super.initState();
    // 接收联系人申请id参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _applyId = params['applyId'];
      }
    });
  }

  // 同意申请
  void agreeApply() async {
    // 发送请求
    await handleApplyApi(
      HandleApplyReq(applyId: _applyId, status: ContactApplyStatusEnum.agree),
    );
    ToastUtils.showGlobalToast(msg: '已同意');
    Navigator.pop(context, ContactApplyStatusEnum.agree);
  }

  // 拒绝申请
  void rejectApply() async {
    // 发送请求
    // 发送请求
    await handleApplyApi(
      HandleApplyReq(applyId: _applyId, status: ContactApplyStatusEnum.reject),
    );
    ToastUtils.showGlobalToast(msg: '已拒绝');
    Navigator.pop(context, ContactApplyStatusEnum.reject);
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
              color: Color.fromRGBO(20, 134, 237, 1),
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
              color: Color.fromRGBO(247, 247, 247, 1),
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
            _buildBtn(),
          ],
        ),
      ),
    );
  }
}
