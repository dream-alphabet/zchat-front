import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/stores/message.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/badge.dart';
import 'package:zchat/widgets/chat_blank.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 聊天
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with AutomaticKeepAliveClientMixin {
  // 会话store
  final _chatSessionStore = Get.find<ChatSessionStore>();
  // 消息store
  final _messageStore = Get.find<MessageController>();
  // 用户store
  final _userController = Get.find<UserController>();

  Widget _buildSessionItem(ChatSessionRes session) {
    return InkClick(
      backgroundColor: Colors.white,
      onTap: () {
        Navigator.pushNamed(
          context,
          RoutePath.chatMessage,
          arguments: {
            'contactId': session.contactId,
            'contactType': session.contactType,
            'sessionId': session.sessionId,
          },
        );
      },
      child: Container(
        padding: EdgeInsetsGeometry.symmetric(vertical: 12.w, horizontal: 15.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color.fromRGBO(232, 232, 232, 1),
              width: 1.w,
            ),
          ),
        ),
        child: Row(
          spacing: 20.w,
          children: [
            // 头像
            Obx(
              () => UnreadCountBadge(
                count: _messageStore.unreadCount[session.sessionId] ?? 0,
                child: ContactAvatar(contactId: session.contactId),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.contactName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    session.lastMessage ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color.fromRGBO(122, 122, 122, 1),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: .only(top: 18.w),
              child: Text(
                formatTimestamp(session.lastReceiveTime),
                style: TextStyle(
                  color: const Color.fromRGBO(122, 122, 122, 1),
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建会话列表
  Widget _buildSessionList() {
    return ListView.builder(
      itemCount: _chatSessionStore.sessionList.length,
      itemBuilder: (context, index) =>
          _buildSessionItem(_chatSessionStore.sessionList[index]),
    );
  }

  // 需要保活
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: Column(
        children: [
          Obx(() => PageHeader(title: '聊天', showLeftAvatar: true, userId: _userController.userInfo.value?.userId)),
          Expanded(
            child: Obx(() {
              return _chatSessionStore.sessionList.isEmpty
                  ? ChatBlank(msg: '请开始聊天吧!')
                  : _buildSessionList();
            }),
          ),
        ],
      ),
    );
  }
}
