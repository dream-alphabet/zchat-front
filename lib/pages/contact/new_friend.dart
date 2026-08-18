import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/event_bus.dart';
import 'package:zchat/common/websocket.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/message.dart';
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

  // 监听websocket服务器推送的消息
  late StreamSubscription<ServerMsgEvent> _streamSubscription;

  // 消息store
  final _messageStore = Get.find<MessageController>();

  @override
  void initState() {
    super.initState();
    // 设置活跃会话为contact_apply
    setActiveSession(UnreadType.contactApply);
    // 监听推送消息
    _streamSubscription = eventBus.on<ServerMsgEvent<ContactApplyRes>>().listen(
      (event) {
        // 消息类型不是联系人申请
        if (event.type != ServerMsgType.contactApply) {
          return;
        }
        // 申请数据
        final apply = event.msg;
        final index = _applyList.indexWhere(
          (item) => item.applyId == apply.applyId,
        );
        if (index >= 0) {
          // 更新
          _applyList[index] = apply;
        } else {
          // 新增
          // 插入到列表中
          _applyList.insert(0, apply);
        }
        setState(() {});
      },
    );
    // 延迟到帧结束再修改
    // 不能在build之前清空因为Obx在build之前重构会有问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 清空联系人未读消息数量
      _messageStore.clearUnreadCount(UnreadType.contactApply);
    });
    _getApplyList();
  }

  // 获取联系人申请列表
  Future<void> _getApplyList() async {
    final res = await getContactApplyListApi(
      ApplyListReq(page: page, pageSize: pageSize),
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
  Widget _buildItemRight(ContactApplyRes apply) {
    return apply.status == ContactApplyStatusEnum.waitHandle
        ? GestureDetector(
            onTap: () async {
              // 跳转到验证好友申请页面, 并等待结果
              final status = await Navigator.pushNamed(
                context,
                RoutePath.verifyApply,
                arguments: {
                  "applyId": apply.applyId,
                  "contactType": apply.contactType,
                },
              );
              // 如果处理了申请
              if (status != null && status is int) {
                setState(() {
                  apply.status = status;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(242, 242, 242, 1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.w),
              child: Text(
                '验证',
                style: TextStyle(fontSize: 15.sp, color: Colors.black),
              ),
            ),
          )
        : Text(
            ContactApplyStatusEnum.getStatusText(apply.status),
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color.fromRGBO(119, 119, 119, 1),
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
          ContactAvatar(contactId: apply.applyUserId),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: showBorder
                      ? BorderSide(
                          color: const Color.fromRGBO(232, 232, 232, 1),
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
                      // 如果是群聊，额外显示群聊名称
                      if (apply.contactType == UserContactTypeEnum.group)
                        Text(
                          apply.groupName ?? '',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: const Color.fromRGBO(20, 134, 237, 1),
                          ),
                        ),
                      Text(
                        apply.contactName,
                        style: TextStyle(fontSize: 16.sp, color: Colors.black),
                      ),
                      Text(
                        apply.applyInfo,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color.fromRGBO(119, 119, 119, 1),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 15.w),
                    child: _buildItemRight(apply),
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
        backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: const Color.fromRGBO(247, 247, 247, 1),
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: const Color.fromRGBO(247, 247, 247, 1),
          // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
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

  @override
  void dispose() {
    // 删除活跃会话
    removeActiveSession();
    // 移除ws监听
    _streamSubscription.cancel();
    super.dispose();
  }
}
