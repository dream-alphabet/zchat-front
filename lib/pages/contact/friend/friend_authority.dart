import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/widgets/page_header.dart';

// 好友权限
class FriendAuthorityPage extends StatefulWidget {
  const FriendAuthorityPage({super.key});

  @override
  State<FriendAuthorityPage> createState() => _FriendAuthorityPageState();
}

class _FriendAuthorityPageState extends State<FriendAuthorityPage> {
  // 联系人id
  String _contactId = '';
  // 当前权限
  int _permission = ContactPermissionEnum.allowMoments;
  // 联系人store
  final _userContactController = Get.find<UserContactController>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        // 接收路由参数
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        _initPermission();
      }
    });
  }

  // 初始化权限
  Future<void> _initPermission() async {
    // 优先从联系人store获取
    final contact = _userContactController.getUserContact(_contactId);
    if (contact != null) {
      _permission = contact.permission;
      setState(() {});
      return;
    }
    // 联系人store没有，从接口获取
    final contactInfo = await getContactInfoApi(_contactId);
    if (contactInfo?.permission != null) {
      _permission = contactInfo!.permission!;
      setState(() {});
    }
  }

  // 更新权限
  void _updatePermission(int permission) async {
    setState(() => _permission = permission);
    await updateContactSettingApi(
      UpdateContactSettingReq(contactId: _contactId, permission: permission),
    );
    // 更新本地store
    _userContactController.updateContact(_contactId, permission: permission);
    ToastUtils.showGlobalToast(msg: '设置成功');
  }

  // 权限选项行
  Widget _buildOptionRow(
    String title,
    String desc,
    int permission,
    bool showBorder,
  ) {
    final selected = _permission == permission;
    return InkWell(
      onTap: () => _updatePermission(permission),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 12.w),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: const Color.fromRGBO(237, 237, 237, 1),
                    width: 1.w,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Column(
              crossAxisAlignment: .start,
              spacing: 3.w,
              children: [
                Text(title, style: TextStyle(fontSize: 16.sp)),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color.fromRGBO(174, 174, 174, 1),
                  ),
                ),
              ],
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected
                  ? const Color.fromRGBO(20, 134, 237, 1)
                  : const Color.fromRGBO(174, 174, 174, 1),
              size: 20.w,
            ),
          ],
        ),
      ),
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
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '朋友权限',
              showLeftBackIcon: true,
              backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
              showRightIcon: false,
              showBorder: false,
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.only(bottom: 5.w),
              child: Column(
                children: [
                  _buildOptionRow(
                    '允许看朋友圈',
                    '对方可以查看你的朋友圈动态',
                    ContactPermissionEnum.allowMoments,
                    true,
                  ),
                  _buildOptionRow(
                    '仅聊天',
                    '对方只能查看你的聊天记录，不能查看你的朋友圈等',
                    ContactPermissionEnum.onlyChat,
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
