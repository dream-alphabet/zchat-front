import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/api/group.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/group.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/page_header.dart';

// 群名称
class GroupNamePage extends StatefulWidget {
  const GroupNamePage({super.key});

  @override
  State<GroupNamePage> createState() => _GroupNamePageState();
}

class _GroupNamePageState extends State<GroupNamePage> {
  // 群聊信息
  Group? _group;

  // 新群名称
  String _newGroupName = '';

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
          _newGroupName = _group?.groupName ?? '';
        });
      }
    });
  }

  // 更新群名称
  void _updateGroupName() async {
    final newGroupName = _newGroupName.trim();
    if (newGroupName.isEmpty) {
      ToastUtils.showGlobalToast(msg: '群名称不能为空');
      return;
    }
    await updateGroupApi(
      _group!.groupId,
      UpdateGroupReq(groupName: newGroupName, groupNotice: ''),
    );
    ToastUtils.showGlobalToast(msg: '修改成功');
    Navigator.pop(context);
  }

  // 构建提示
  Widget _buildNotice() {
    return Column(
      spacing: 10.w,
      children: [
        Text('修改群聊名称', style: TextStyle(fontSize: 20.sp)),
        Text('修改群聊名称后，将在群内通知其他成员。'),
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
          ContactAvatar(contactId: _group?.groupId ?? '', shape: .rectangle),
          Expanded(
            child: TextField(
              onChanged: (value) {
                _newGroupName = value;
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
                hintText: _group?.groupName ?? '请输入群名称',
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
      onTap: _updateGroupName,
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
}
