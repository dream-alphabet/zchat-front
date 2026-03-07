import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 聊天消息组件
class ChatMessage extends StatelessWidget {
  // 消息对象
  final ChatMessageRes message;
  // 用户信息store
  final _userController = Get.find<UserController>();

  ChatMessage({super.key, required this.message});

  // 构建文本消息
  Widget _buildTextMsg(String msg) {
    return Padding(
      padding: _isSelf
          ? EdgeInsets.only(right: 6.w)
          : EdgeInsets.only(left: 6.w),
      child: CustomPaint(
        painter: BubbleArrowPainter(isSelf: _isSelf),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.w),
          decoration: BoxDecoration(
            color: _isSelf ? Color.fromRGBO(20, 134, 237, 1) : Colors.white,
            borderRadius: .circular(8.r),
          ),
          child: SelectableText(
            msg,
            style: TextStyle(
              color: _isSelf ? Colors.white : Colors.black,
              fontSize: 16.sp,
            ),
          ),
        ),
      ),
    );
  }

  // 构建消息内容
  Widget _buildMsgContent() {
    // 消息类型
    final messageType = message.messageType;
    // 文本消息
    if (messageType == MessageTypeEnum.text.type) {
      return _buildTextMsg(message.messageContent);
    }
    return _buildTextMsg('未知消息类型');
  }

  // 是否是当前用户发送的消息
  bool get _isSelf =>
      _userController.userInfo.value?.userId == message.sendUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 10.w, right: 10.w, bottom: 10.w),
      child: Row(
        mainAxisAlignment: _isSelf
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.w,
        children: _isSelf
            ? [
                // 头像
                ContactAvatar(imageUrl: 'lib/assets/test/01.png'),
                Container(
                  constraints: BoxConstraints(maxWidth: 240.w),
                  child: _buildMsgContent(),
                ),
              ].reversed.toList()
            : [
                // 头像
                ContactAvatar(imageUrl: 'lib/assets/test/01.png'),
                Container(
                  constraints: BoxConstraints(maxWidth: 240.w),
                  child: _buildMsgContent(),
                ),
              ],
      ),
    );
  }
}

// 文本消息气泡左侧箭头绘制器
class BubbleArrowPainter extends CustomPainter {
  final bool isSelf;

  BubbleArrowPainter({required this.isSelf});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelf ? Color.fromRGBO(20, 134, 237, 1) : Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isSelf) {
      // 绘制右侧小三角形箭头
      path.moveTo(size.width + 6.w, 12.w); // 起点
      path.lineTo(size.width, 7.w);
      path.lineTo(size.width, 17.w);
    } else {
      // 绘制左侧小三角形箭头
      path.moveTo(-6.w, 12.w); // 起点
      path.lineTo(0, 7.w);
      path.lineTo(0, 17.w);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
