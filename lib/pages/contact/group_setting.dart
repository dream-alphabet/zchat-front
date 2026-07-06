import 'dart:convert';
import 'dart:math';

import 'package:dashed_border/dashed_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/api/group.dart';
import 'package:zchat/common/animation.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/model/group.dart';
import 'package:zchat/pages/contact/contact_select.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/dialog.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/page_header.dart';

// 群聊设置
class GroupSettingPage extends StatefulWidget {
  const GroupSettingPage({super.key});

  @override
  State<GroupSettingPage> createState() => _GroupSettingPageState();
}

class _GroupSettingPageState extends State<GroupSettingPage> {
  // 会话store
  final _sessionStore = Get.find<ChatSessionStore>();

  // 成员列表
  List<UserContactRes> _memberList = [];

  // 成员列表区域显示几行
  int get _memberRows => ((min(_memberList.length, 24) + 1) / 5).ceil();

  // 群聊id
  String _groupId = '';

  // 群聊信息
  Group? _group;

  @override
  void initState() {
    super.initState();
    // 接收群聊id参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _groupId = params['groupId'];
        _getGroupSettings();
      }
    });
  }

  // 获取群聊设置信息
  void _getGroupSettings() async {
    final res = await getGroupSettingsApi(_groupId);
    _memberList = res.members;
    _group = res.group;
    setState(() {});
  }

  // 发送群聊卡片
  Future<void> _sendGroupCard(
    UserContactRes receiver,
    UserContactRes groupInfo,
  ) async {
    // 发送消息
    final msg = await sendMessageApi(
      SendMsgReq(
        contactId: receiver.contactId,
        contactType: UserContactTypeEnum.user,
        messageType: MessageTypeEnum.personCard.type,
        messageContent: MessageTypeEnum.personCard.messageContent,
        data: jsonEncode(groupInfo.toJson()),
      ),
    );
    // 更新会话的lastMessage和lastReceiveTime
    _sessionStore.updateLastMessage(
      msg.sessionId,
      MessageTypeEnum.personCard.messageContent,
      msg.sendTime,
    );
  }

  // 邀请好友加入群聊(发送群聊卡片)
  void _inviteFriend() {
    // 跳转到联系人选择页面选择群成员
    Navigator.push(
      context,
      RouteUtils.slideUp(
        (context) => ContactSelectPage(
          onSelect: (receiver) async {
            final groupInfo = UserContactRes(
              contactId: _groupId,
              contactName: _group?.groupName ?? '',
            );
            final result = await showSendConfirmModal(
              context,
              receiver,
              groupInfo,
              type: '群聊',
            );
            // 用户是否点击发送按钮
            final confirm = result != null && result;
            // 用户点击了确认发送
            if (confirm) {
              await _sendGroupCard(receiver, groupInfo);
              // 提示已发送
              await showPromptDialog(context, '已发送');
            }
            return confirm;
          },
        ),
      ),
    );
  }

  // 构建一行成员
  Widget _buildRow(int index) {
    // 开始索引
    final startIndex = index * 5;
    return Padding(
      padding: EdgeInsetsGeometry.only(bottom: 10.w),
      child: Row(
        mainAxisAlignment: .spaceAround,
        crossAxisAlignment: .start,
        children: List.generate(5, (index) {
          // 索引越界，使用SizedBox占位
          if (startIndex + index > _memberList.length) {
            return SizedBox(width: 45.w);
          }
          // 末尾追加的+号
          if (startIndex + index == _memberList.length) {
            return GestureDetector(
              onTap: _inviteFriend,
              child: Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: DashedBorder(
                    color: Color.fromRGBO(175, 175, 175, 1), // 边框颜色
                    width: 1.w, // 边框宽度
                    dashLength: 8.w, // 虚线线段长度
                    dashGap: 4.w, // 虚线间隔
                    borderRadius: BorderRadius.circular(8.r), // 圆角
                  ),
                ),
                alignment: .center,
                child: Icon(
                  Icons.add,
                  size: 25.w,
                  color: Color.fromRGBO(175, 175, 175, 1),
                ),
              ),
            );
          }
          return GestureDetector(
            onTap: () {
              // 前往联系人信息页面
              Navigator.pushNamed(
                context,
                RoutePath.contactInfo,
                arguments: {'contactId': _memberList[index].contactId},
              );
            },
            child: Column(
              spacing: 5.w,
              children: [
                ContactAvatar(
                  contactId: _memberList[index].contactId,
                  shape: .rectangle,
                  size: 45,
                ),
                Text(_memberList[index].contactName),
              ],
            ),
          );
        }),
      ),
    );
  }

  // 构建群聊成员列表区域
  Widget _buildGroupMemberList() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      color: Colors.white,
      child: Column(
        children: [
          Column(
            children: List.generate(_memberRows, (index) => _buildRow(index)),
          ),
          if (_memberList.length > 24)
            GestureDetector(
              onTap: () async {
                // 跳转到联系人选择页面，联系人数据使用_memberList
                // 点击联系人时跳转到联系人信息页面
                final contact =
                    await Navigator.pushNamed(
                          context,
                          RoutePath.contactSelect,
                          arguments: {
                            'contactList': _memberList,
                            'groupId': _groupId,
                          },
                        )
                        as UserContactRes?;
                // 没有选择
                if (contact == null) {
                  return;
                }
                // 前往联系人信息页面
                Navigator.pushNamed(
                  context,
                  RoutePath.contactInfo,
                  arguments: {'contactId': contact.contactId},
                );
              },
              child: Row(
                mainAxisSize: .min,
                spacing: 5.w,
                children: [
                  Text(
                    '更多群成员',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Color.fromRGBO(175, 175, 175, 1),
                    ),
                  ),
                  Icon(
                    MyIcon.arrowRight,
                    size: 16.sp,
                    color: Color.fromRGBO(175, 175, 175, 1),
                  ),
                ],
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
        backgroundColor: Color.fromRGBO(247, 247, 247, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color.fromRGBO(247, 247, 247, 1), // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color.fromRGBO(
            247,
            247,
            247,
            1,
          ), // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Color.fromRGBO(247, 247, 247, 1),
      body: SafeArea(
        child: ListView(
          children: [
            PageHeader(
              showLeftBackIcon: true,
              showBorder: false,
              title: '群聊设置',
              rightIconList: [
                GestureDetector(
                  onTap: () async {
                    // 跳转到联系人选择页面，联系人数据使用_memberList
                    // 点击联系人时跳转到联系人信息页面
                    final contact =
                        await Navigator.pushNamed(
                              context,
                              RoutePath.contactSelect,
                              arguments: {
                                'contactList': _memberList,
                                'groupId': _groupId,
                              },
                            )
                            as UserContactRes?;
                    // 没有选择
                    if (contact == null) {
                      return;
                    }
                    // 前往联系人信息页面
                    Navigator.pushNamed(
                      context,
                      RoutePath.contactInfo,
                      arguments: {'contactId': contact.contactId},
                    );
                  },
                  child: Icon(MyIcon.search, size: 25.w),
                ),
              ],
              showRightIcon: true,
            ),
            _buildGroupMemberList(),
          ],
        ),
      ),
    );
  }
}
