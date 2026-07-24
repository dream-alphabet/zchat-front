import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/group.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/group.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/page_header.dart';

// 群公告
class GroupNoticePage extends StatefulWidget {
  const GroupNoticePage({super.key});

  @override
  State<GroupNoticePage> createState() => _GroupNoticePageState();
}

class _GroupNoticePageState extends State<GroupNoticePage> {
  // 群聊信息
  Group? _group;

  // 群公告输入框控制器
  final _groupNoticeController = TextEditingController();

  // 用户store
  final _userController = Get.find<UserController>();

  // 当前用户是否是群主
  bool get isGroupOwner =>
      _userController.userInfo.value?.userId == _group?.groupOwnerId;

  @override
  void initState() {
    super.initState();
    // 接收路由参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        setState(() {
          _group = params['group'];
          _groupNoticeController.text = _group?.groupNotice ?? '';
        });
      }
    });
  }

  // 修改群公告
  void _updateGroupNotice() async {
    final newNotice = _groupNoticeController.text.trim();
    if (newNotice.isEmpty) {
      ToastUtils.showGlobalToast(msg: '群公告不能为空');
      return;
    }
    await updateGroupApi(
      _group!.groupId,
      UpdateGroupReq(groupName: '', groupNotice: newNotice),
    );
    ToastUtils.showGlobalToast(msg: '修改成功');
    Navigator.pop(context);
  }

  // 构建提示
  Widget _buildNotice() {
    return isGroupOwner
        ? Column(
            spacing: 10.w,
            children: [
              Text('修改群公告', style: TextStyle(fontSize: 20.sp)),
              Text('修改群公告后，将在群内通知其他成员。'),
            ],
          )
        : Center(
            child: Text('群公告', style: TextStyle(fontSize: 20.sp)),
          );
  }

  // 构建群公告输入框
  Widget _buildInput() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w),
      child: TextField(
        controller: _groupNoticeController,
        textInputAction: .done,
        maxLength: 200,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: '请输入群公告',
          hintStyle: TextStyle(color: Color.fromRGBO(174, 174, 174, 1)),
          focusedBorder: OutlineInputBorder(
            borderRadius: .circular(8.r),
            borderSide: BorderSide(color: Colors.black, width: 1.w),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: .circular(8.r),
            borderSide: BorderSide(color: Colors.black, width: 1.w),
          ),
          border: OutlineInputBorder(
            borderRadius: .circular(8.r),
            borderSide: BorderSide(color: Colors.black, width: 1.w),
          ),
        ),
      ),
    );
  }

  // 构建查看群公告区域
  Widget _buildGroupNoticeView() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        border: .all(color: Colors.black, width: 1.w),
        borderRadius: .circular(8.r),
      ),
      child: Text(
        _group != null && _group!.groupNotice.isNotEmpty
            ? _group!.groupNotice
            : '暂无群公告',
      ),
    );
  }

  // 完成按钮
  Widget _buildFinishBtn() {
    return GestureDetector(
      onTap: _updateGroupNotice,
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
            SizedBox(height: 20.w),
            isGroupOwner ? _buildInput() : _buildGroupNoticeView(),
            Expanded(child: SizedBox()),
            if (isGroupOwner)
              Column(
                children: [
                  SizedBox(height: 20.w),
                  _buildFinishBtn(),
                  SizedBox(height: 20.w),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNoticeController.dispose();
    super.dispose();
  }
}
