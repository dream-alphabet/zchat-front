import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/pages/chat/widgets/chat_message.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/page_header.dart';

// 聊天记录详情页(合并转发)
class ChatRecordDetailPage extends StatefulWidget {
  // 聊天记录快照消息列表
  final List<ChatMessageRes> messages;

  const ChatRecordDetailPage({super.key, required this.messages});

  @override
  State<ChatRecordDetailPage> createState() => _ChatRecordDetailPageState();
}

class _ChatRecordDetailPageState extends State<ChatRecordDetailPage> {
  final _userController = Get.find<UserController>();

  // 列表滚动控制器
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '聊天记录',
              showLeftBackIcon: true,
              showRightIcon: false,
              backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 10.w),
                itemCount: widget.messages.length,
                itemBuilder: (context, index) {
                  final message = widget.messages[index];
                  final isSelf =
                      _userController.userInfo.value?.userId ==
                          message.sendUserId;
                  return Padding(
                    padding: EdgeInsets.only(top: 10.w, bottom: 5.w),
                    child: Column(
                      crossAxisAlignment: isSelf
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // 发送者昵称+时间(与气泡边缘对齐)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text(
                            '${message.sendUserNickname ?? ''}  '
                            '${message.sendTime > 0 ? formatTimestamp(message.sendTime) : ''}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: 4.w),
                        ChatMessage(
                          message: message,
                          scrollController: _scrollController,
                          onShareMessage: (_, _) {},
                          onVideoOrVoiceCall: (_) {},
                          showMenu: false,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
