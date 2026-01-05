import 'package:flutter/material.dart';

// 聊天
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: Center(
        child: Text('聊天'),
       ),
    );
  }
}