import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/widgets/page_header.dart';

// 聊天
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // 会话列表
  final List<ChatSession> _sessionList = [
    ChatSession(
      sessionId: '1',
      contactName: 'dream',
      contactId: 'U1',
      lastMessage: '你好的回调函数豆瓣萨哈帝国萨城西北角爱词霸',
      lastReceiveTime: 1767600153280,
      noReadCount: 0,
    ),
    ChatSession(
      sessionId: '1',
      contactName: 'dream',
      contactId: 'U1',
      lastMessage: '你好',
      lastReceiveTime: 1767600153280,
      noReadCount: 2,
    ),
  ];

  // 构建空白内容
  Widget _buildBlank() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 30.w,
      children: [
        Image.asset(
          'lib/assets/images/chat-blank.png',
          width: 113.w,
          height: 107.w,
        ),
        Text(
          '请开始聊天吧!',
          style: TextStyle(fontSize: 16.sp, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildSessionItem(ChatSession session) {
    return Container(
      padding: EdgeInsetsGeometry.symmetric(vertical: 12.w, horizontal: 10.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(232, 232, 232, 1),
            width: 1.w,
          ),
        ),
        color: Colors.white
      ),
      child: Row(
        spacing: 10.w,
        children: [
          // 头像
          ClipRRect(
            borderRadius: BorderRadius.circular(20.w),
            child: Image.asset(
              'lib/assets/test/01.png',
              width: 40.w,
              height: 40.w,
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
                  session.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color.fromRGBO(122, 122, 122, 1),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 徽标
              session.noReadCount > 0 ? Container(
                width: 16.w,
                height: 16.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 55, 66, 1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${session.noReadCount}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ) : SizedBox(height: 16.w),
              SizedBox(height: 2.w),
              // 消息时间
              Text(
                formatTimestamp(session.lastReceiveTime),
                style: TextStyle(
                  color: Color.fromRGBO(122, 122, 122, 1),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建会话列表
  Widget _buildSessionList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _sessionList.length,
      itemBuilder: (context, index) => _buildSessionItem(_sessionList[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(237, 237, 237, 1),
      body: Column(
        children: [
          PageHeader(title: '聊天'),
          Expanded(
            child: _sessionList.isEmpty ? _buildBlank() : _buildSessionList(),
          ),
        ],
      ),
    );
  }
}
