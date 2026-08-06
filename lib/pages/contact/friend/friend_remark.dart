import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/session.dart';

// 好友备注
class FriendRemarkPage extends StatefulWidget {
  const FriendRemarkPage({super.key});

  @override
  State<FriendRemarkPage> createState() => _FriendRemarkPageState();
}

class _FriendRemarkPageState extends State<FriendRemarkPage> {
  // 备注输入框控制器
  final _remarkController = TextEditingController();

  // 备注
  String _remark = '';

  // 备注是否为空
  bool get _isRemarkEmpty => _remark.trim().isEmpty;

  // 联系人id
  String _contactId = '';

  // 联系人store
  final _userContactController = Get.find<UserContactController>();

  // 会话store
  final _sessionStore = Get.find<ChatSessionStore>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        // 接收路由参数
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        final contact = _userContactController.findUserContact(_contactId, UserContactTypeEnum.user);
        if (contact != null) {
          setState(() {
            _remark = contact.remark ?? '';
            _remarkController.text = _remark;
          });
        }
      }
    });
  }

  // 更新备注
  void _updateRemark() async {
    // 备注为空
    if (_isRemarkEmpty) {
      return;
    }
    await updateContactSettingApi(
      UpdateContactSettingReq(contactId: _contactId, remark: _remark),
    );
    // 修改本地store remark
    _userContactController.updateContact(_contactId, remark: _remark);
    _sessionStore.updateRemark(_remark, contactId: _contactId);
    ToastUtils.showGlobalToastAsync(msg: '更新成功').whenComplete(() {
      Navigator.pop(context);
    });
  }

  // 构建顶部按钮
  Widget _buildTopBtns() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 15.w, vertical: 10.w),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Text('取消'),
          ),
          GestureDetector(
            onTap: _updateRemark,
            child: Container(
              decoration: BoxDecoration(
                color: _isRemarkEmpty
                    ? Color.fromRGBO(242, 242, 242, 1)
                    : Color.fromRGBO(20, 134, 237, 1),
                borderRadius: .circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.w),
              child: Text(
                '完成',
                style: TextStyle(
                  color: _isRemarkEmpty
                      ? Color.fromRGBO(207, 207, 207, 1)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建输入框
  Widget _buildInput() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 10.w),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 5.w,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(left: 10.w),
            child: Text(
              '备注',
              style: TextStyle(color: Color.fromRGBO(110, 110, 110, 1)),
            ),
          ),
          TextField(
            controller: _remarkController,
            onChanged: (value) {
              setState(() {
                _remark = value;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Color.fromRGBO(247, 247, 247, 1),
              hintText: '添加备注',
              hintStyle: TextStyle(
                color: const Color.fromRGBO(122, 122, 122, 1),
                fontSize: 16.sp,
              ),
              constraints: BoxConstraints(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 8.w,
              ),
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
        child: Column(
          children: [
            _buildTopBtns(),
            SizedBox(height: 30.w),
            Text(
              '设置备注',
              style: TextStyle(fontSize: 22.sp, fontWeight: .w500),
            ),
            SizedBox(height: 30.w),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }
}
