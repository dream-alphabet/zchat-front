import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/group.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/group.dart';
import 'package:zchat/widgets/page_header.dart';

import '../../stores/contact.dart';
import '../../stores/session.dart';

// 创建群聊
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  // 联系人store
  final _userContactController = Get.find<UserContactController>();

  // 聊天会话store
  final _chatSessionStore = Get.find<ChatSessionStore>();

  // 群公告输入框控制器
  final _groupNoticeController = TextEditingController();

  // 群名称输入框控制器
  final _groupNameController = TextEditingController();

  // 创建群聊
  void _create() async {
    // 群名称
    final groupName = _groupNameController.text.trim();
    // 群名称不能为空
    if (groupName.isEmpty) {
      return ToastUtils.showGlobalToast(msg: '群名称不能为空');
    }
    // 群公告
    final groupNotice = _groupNoticeController.text.trim();
    print('群名称: $groupName, 群公告: $groupNotice');
    await createGroupApi(
      CreateGroupReq(groupName: groupName, groupNotice: groupNotice),
    );
    await ToastUtils.showGlobalToastAsync(msg: '创建成功');
    Navigator.pop(context);
    // 更新会话和群聊列表
    await _userContactController.getGroupList();
    await _chatSessionStore.getSessionList();
  }

  // 群名称
  Widget _buildGroupName() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 30.w, vertical: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.w,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(left: 15.w),
            child: Text(
              '群名称',
              style: TextStyle(color: Color.fromRGBO(108, 109, 109, 1)),
            ),
          ),
          TextField(
            controller: _groupNameController,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: Colors.black, fontSize: 16.sp),
            maxLength: 20,
            maxLines: 1,
            // 去掉计数文本
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => SizedBox(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Color.fromRGBO(247, 247, 247, 1),
              hintText: '请输入群名称',
              hintStyle: TextStyle(
                color: Color.fromRGBO(178, 178, 178, 1),
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

  // 群公告
  Widget _buildGroupNotice() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 30.w, vertical: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.w,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(left: 15.w),
            child: Text(
              '群公告',
              style: TextStyle(color: Color.fromRGBO(108, 109, 109, 1)),
            ),
          ),
          TextField(
            controller: _groupNoticeController,
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
                }) => SizedBox(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Color.fromRGBO(247, 247, 247, 1),
              hintText: '请输入群公告',
              hintStyle: TextStyle(
                color: Color.fromRGBO(178, 178, 178, 1),
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

  // 创建按钮
  Widget _buildCreateBtn() {
    return GestureDetector(
      onTap: _create,
      child: Container(
        width: 100.w,
        padding: EdgeInsets.symmetric(vertical: 12.w),
        decoration: BoxDecoration(
          color: Color.fromRGBO(20, 134, 237, 1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        alignment: Alignment.center,
        child: Text(
          '创建',
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
          systemNavigationBarColor: Colors.white,
          // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              PageHeader(
                title: '创建群聊',
                showLeftBackIcon: true,
                showRightIcon: false,
                showBorder: false,
                backgroundColor: Colors.white,
              ),
              _buildGroupName(),
              _buildGroupNotice(),
              SizedBox(height: 50.w),
              _buildCreateBtn(),
            ],
          ),
        ),
      ),
    );
  }
}
