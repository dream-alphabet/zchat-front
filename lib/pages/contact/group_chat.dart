import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/widgets/chat_blank.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 群聊
class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  // 联系人store
  final _userContactController = Get.find<UserContactController>();
  // 会话store
  final _sessionStore = Get.find<ChatSessionStore>();

  // 列表项
  Widget _buildListItem(UserContactRes group, bool showBorder) {
    return InkClick(
      backgroundColor: Colors.white,
      onTap: () {
        // 优先使用已存在的会话id，无会话时传空串(发送消息后自动创建会话)
        final session = _sessionStore.sessionList.firstWhereOrNull(
          (s) => s.contactId == group.contactId,
        );
        Navigator.pushNamed(
          context,
          RoutePath.chatMessage,
          arguments: {
            'contactId': group.contactId,
            'contactType': UserContactTypeEnum.group,
            'sessionId': session?.sessionId ?? '',
          },
        );
      },
      child: Container(
        padding: EdgeInsets.only(left: 15.w),
        child: Row(
          spacing: 15.w,
          children: [
            ContactAvatar(contactId: group.contactId),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.w),
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
                child: Container(
                  height: 40.w,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    group.contactName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black, fontSize: 15.w),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 群聊列表
  Widget _buildGroupList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        _userContactController.groupList.length,
        (index) => _buildListItem(
          _userContactController.groupList[index],
          index < _userContactController.groupList.length - 1,
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
      body: ListView(
        children: [
          const PageHeader(title: '群聊', showLeftBackIcon: true),
          Obx(() {
            return _userContactController.groupList.isEmpty
                ? Padding(
                    padding: EdgeInsetsGeometry.only(top: 30.w),
                    child: ChatBlank(msg: '还没有群聊，快去找朋友创建吧!'),
                  )
                : _buildGroupList();
          }),
        ],
      ),
    );
  }
}
