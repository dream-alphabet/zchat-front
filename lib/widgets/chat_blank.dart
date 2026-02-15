import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 空内容组件
class ChatBlank extends StatelessWidget {
  final String msg;

  const ChatBlank({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
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
          msg,
          style: TextStyle(fontSize: 16.sp, color: Colors.black),
        ),
      ],
    );
  }
}
