import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/widgets/chat_blank.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 新的朋友
class NewFriendPage extends StatefulWidget {
  const NewFriendPage({super.key});

  @override
  State<NewFriendPage> createState() => _NewFriendPageState();
}

class _NewFriendPageState extends State<NewFriendPage> {
  // 申请列表
  List<ContactApplyRes> _applyList = [];
  // 当前页码
  int page = 1;
  // 每页条数
  int pageSize = 10;

  @override
  void initState() {
    super.initState();
    _getApplyList();
  }

  // 获取联系人申请列表
  Future<void> _getApplyList() async {
    final res = await getContactApplyListApi(
      ApplyListReq(
        page: page,
        pageSize: pageSize,
        contactType: UserContactTypeEnum.user,
      ),
    );
    // 申请列表
    _applyList = res.list
        .map((item) => ContactApplyRes.fromJson(item))
        .toList();
    setState(() {});
  }

  // 空白内容
  Widget _buildEmpty() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsetsGeometry.only(top: 60.w),
        child: ChatBlank(msg: '快去寻找好友吧!'),
      ),
    );
  }

  // 申请列表项右侧处理按钮或状态文本
  Widget _buildItemRight(int status) {
    return status == ContactApplyStatusEnum.waitHandle
        ? Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(242, 242, 242, 1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.w),
            child: Text(
              '验证',
              style: TextStyle(fontSize: 15.sp, color: Colors.black),
            ),
          )
        : Text(
            ContactApplyStatusEnum.getStatusText(status),
            style: TextStyle(
              fontSize: 16.sp,
              color: Color.fromRGBO(119, 119, 119, 1),
            ),
          );
  }

  // 申请列表项
  Widget _buildApplyListItem(ContactApplyRes apply, bool showBorder) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 15.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 15.w,
        children: [
          // 头像
          ContactAvatar(imageUrl: 'lib/assets/test/01.png'),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: showBorder
                      ? BorderSide(
                          color: Color.fromRGBO(232, 232, 232, 1),
                          width: 1.w,
                        )
                      : BorderSide.none,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    apply.status == ContactApplyStatusEnum.waitHandle
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    spacing: 4.w,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apply.contactName,
                        style: TextStyle(fontSize: 16.sp, color: Colors.black),
                      ),
                      Text(
                        apply.applyInfo,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color.fromRGBO(119, 119, 119, 1),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 15.w),
                    child: GestureDetector(
                      onTap: () {
                        // 跳转到验证好友申请页面
                        Navigator.pushNamed(context, RoutePath.verifyApply);
                      },
                      child: _buildItemRight(apply.status),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 申请列表
  Widget _buildApplyList() {
    return SliverList.builder(
      itemCount: _applyList.length,
      itemBuilder: (ctx, index) => InkClick(
        onTap: () {
          // 跳转到联系人详情页面
          Navigator.pushNamed(
            context,
            RoutePath.contactInfo,
            arguments: {'contactId': _applyList[index].applyUserId},
          );
        },
        child: _buildApplyListItem(
          _applyList[index],
          index < _applyList.length - 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Color.fromRGBO(247, 247, 247, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color.fromRGBO(247, 247, 247, 1),
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color.fromRGBO(247, 247, 247, 1), // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Color.fromRGBO(247, 247, 247, 1),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: '新的朋友',
                showLeftBackIcon: true,
                showRightIcon: false,
              ),
            ),
            _applyList.isEmpty ? _buildEmpty() : _buildApplyList(),
          ],
        ),
      ),
    );
  }
}
