import 'dart:convert';
import 'dart:math';

import 'package:dashed_border/dashed_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/api/group.dart';
import 'package:zchat/common/animation.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/model/group.dart';
import 'package:zchat/pages/contact/contact_select.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/dialog.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/page_header.dart';
import 'package:zchat/widgets/wechat_switch.dart';

// 群聊设置
class GroupSettingPage extends StatefulWidget {
  const GroupSettingPage({super.key});

  @override
  State<GroupSettingPage> createState() => _GroupSettingPageState();
}

class _GroupSettingPageState extends State<GroupSettingPage> {
  // 会话store
  final _sessionStore = Get.find<ChatSessionStore>();

  // 联系人store
  final _userContactController = Get.find<UserContactController>();

  // 用户store
  final _userController = Get.find<UserController>();

  // 成员列表
  List<UserContactRes> _memberList = [];

  // 成员列表区域显示几行
  int get _memberRows => ((min(_memberList.length, 24) + 1) / 5).ceil();

  // 次要文字/图标颜色
  static const _hintColor = Color.fromRGBO(174, 174, 174, 1);
  // 列表分隔线颜色
  static const _dividerColor = Color.fromRGBO(247, 247, 247, 1);

  // 群聊id
  String _groupId = '';

  // 群聊信息
  Group? _group;

  // 当前用户是否是群主
  bool get isGroupOwner =>
      _userController.userInfo.value?.userId == _group?.groupOwnerId;

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
    PersonCardData groupInfo,
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
            final groupInfo = PersonCardData(
              contactId: _groupId,
              contactType: UserContactTypeEnum.group,
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

  // 跳转到全部群成员页面，点击成员跳转到联系人信息页面
  Future<void> _showAllGroupMembers() async {
    final contact =
        await Navigator.pushNamed(
              context,
              RoutePath.contactSelect,
              arguments: {'contactList': _memberList, 'groupId': _groupId},
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
  }

  // 构建设置行（左侧标题，右侧内容+箭头）
  Widget _buildSettingRow(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      spacing: 10.w,
      children: [
        Text(title),
        Row(
          mainAxisSize: .min,
          spacing: 5.w,
          children: [
            ?trailing,
            Icon(MyIcon.arrowRight, size: 16.sp, color: _hintColor),
          ],
        ),
      ],
    );
  }

  // 构建设置列表行（点击效果 + 水平边距 + 可选底部分隔线）
  Widget _buildListItem({
    required VoidCallback onTap,
    required Widget child,
    bool showBorder = false,
  }) {
    return InkClick(
      onTap: onTap,
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        padding: EdgeInsets.symmetric(vertical: 10.w),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(color: _dividerColor, width: 1.w),
                )
              : null,
        ),
        child: child,
      ),
    );
  }

  // 解散/退出群聊
  void _dissolveOrExitGroup() async {
    // 弹出确认框
    final confirm = await showPromptDialog(
      context,
      showCancel: true,
      '是否${isGroupOwner ? '解散' : '退出'}该群聊',
    );
    // 取消操作
    if (confirm == null || !confirm) {
      return;
    }
    if (isGroupOwner) {
      await dissolveGroupApi(_groupId);
      ToastUtils.showGlobalToast(msg: '群聊已解散');
      // 删除联系人列表和会话列表中的群聊
      _sessionStore.delSession(_groupId);
      _userContactController.delGroup(_groupId);
      // 返回上一页并告知群聊已解散
      Navigator.pop(context, UserContactStatusEnum.delete);
    } else {
      await delContactApi(_groupId, UserContactTypeEnum.group);
      ToastUtils.showGlobalToast(msg: '退出成功');
      // 删除联系人和会话
      _userContactController.delGroup(_groupId);
      _sessionStore.delSession(_groupId);
      Navigator.pop(context, UserContactStatusEnum.delete);
    }
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
                    color: const Color.fromRGBO(175, 175, 175, 1), // 边框颜色
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
                  color: const Color.fromRGBO(175, 175, 175, 1),
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
            child: SizedBox(
              height: 60.w + 14.sp,
              width: 60.w,
              child: Column(
                mainAxisAlignment: .spaceBetween,
                children: [
                  ContactAvatar(
                    contactId: _memberList[index].contactId,
                    shape: .rectangle,
                    size: 45,
                  ),
                  Text(
                    _memberList[index].contactName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black,
                      overflow: .ellipsis,
                    ),
                  ),
                ],
              ),
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
              onTap: _showAllGroupMembers,
              child: Row(
                mainAxisSize: .min,
                spacing: 5.w,
                children: [
                  Text(
                    '更多群成员',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: const Color.fromRGBO(175, 175, 175, 1),
                    ),
                  ),
                  Icon(
                    MyIcon.arrowRight,
                    size: 16.sp,
                    color: const Color.fromRGBO(175, 175, 175, 1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 群聊名称
  Widget _buildGroupName() {
    return _buildSettingRow(
      '群聊名称',
      trailing: Text(
        _group?.groupName ?? '',
        style: TextStyle(color: _hintColor, overflow: .ellipsis),
      ),
    );
  }

  // 群二维码
  Widget _buildGroupQrCode() {
    return _buildSettingRow(
      '群二维码',
      trailing: Icon(MyIcon.qrCode, size: 20.sp, color: _hintColor),
    );
  }

  // 群公告
  Widget _buildGroupNotice() => _buildSettingRow('群公告');

  // 群备注
  Widget _buildRemark() => _buildSettingRow('群备注');

  // 我在群里的昵称
  Widget _buildGroupNickname() => _buildSettingRow('我在群里的昵称');

  // 构建功能区域
  Widget _buildFunction() {
    // 功能项列表（页面组件 + 对应路由）
    final functionList = <(Widget, String)>[
      (_buildGroupName(), RoutePath.groupName),
      (_buildGroupQrCode(), RoutePath.groupQrcode),
      (_buildGroupNotice(), RoutePath.groupNotice),
      (_buildRemark(), RoutePath.groupRemark),
      (_buildGroupNickname(), RoutePath.groupNickname),
    ];
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: List.generate(
          functionList.length,
          (index) {
            final (item, path) = functionList[index];
            return _buildListItem(
              onTap: () {
                // 群聊名称只有群主可以修改
                if (path == RoutePath.groupName && !isGroupOwner) {
                  showPromptDialog(context, '只有群主才可以修改', confirmText: '知道了');
                  return;
                }
                Navigator.pushNamed(
                  context,
                  path,
                  arguments: {'group': _group, 'groupId': _groupId},
                );
              },
              showBorder: index < functionList.length - 1,
              child: item,
            );
          },
        ),
      ),
    );
  }

  // 切换消息免打扰
  void _toggleDisturb(bool value) async {
    final disturb = value ? DisturbStatusEnum.open : DisturbStatusEnum.close;
    await updateContactSettingApi(
      UpdateContactSettingReq(contactId: _groupId, disturb: disturb),
    );
    // 更新本地store
    _userContactController.updateContact(_groupId, disturb: disturb);
    // 同步会话列表的免打扰状态(用于红点角标)
    _sessionStore.updateDisturb(_groupId, disturb);
    setState(() {});
  }

  // 消息免打扰
  Widget _buildDisturb() {
    // 当前免打扰状态
    final contact = _userContactController.getUserContact(_groupId);
    final disturb = contact?.disturb == DisturbStatusEnum.open;
    return _buildListItem(
      onTap: () {},
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text('消息免打扰'),
          WeChatSwitch(value: disturb, onChanged: _toggleDisturb),
        ],
      ),
    );
  }

  // 查找聊天记录
  Widget _buildChatHistory() {
    return _buildListItem(
      onTap: () {
        Navigator.pushNamed(
          context,
          RoutePath.chatHistory,
          arguments: {'contactId': _groupId},
        );
      },
      child: _buildSettingRow('查找聊天记录'),
    );
  }

  // 构建退出/解散群聊按钮
  Widget _buildExitGroupBtn() {
    return _buildListItem(
      onTap: _dissolveOrExitGroup,
      child: Center(
        child: Text(
          isGroupOwner ? '解散群聊' : '退出群聊',
          style: TextStyle(
            fontSize: 16.sp,
            color: Color.fromRGBO(241, 90, 81, 1),
          ),
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
          statusBarColor: const Color.fromRGBO(247, 247, 247, 1), // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: const Color.fromRGBO(
            247,
            247,
            247,
            1,
          ), // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
      body: SafeArea(
        child: ListView(
          children: [
            PageHeader(
              showLeftBackIcon: true,
              showBorder: false,
              title: '群聊设置',
              rightIconList: [
                GestureDetector(
                  onTap: _showAllGroupMembers,
                  child: Icon(MyIcon.search, size: 25.w),
                ),
              ],
              showRightIcon: true,
            ),
            _buildGroupMemberList(),
            SizedBox(height: 10.w),
            _buildFunction(),
            SizedBox(height: 10.w),
            _buildDisturb(),
            _buildChatHistory(),
            SizedBox(height: 10.w),
            _buildExitGroupBtn(),
          ],
        ),
      ),
    );
  }
}
