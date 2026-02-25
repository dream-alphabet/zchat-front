import 'package:flutter/material.dart';

// 聊天消息页面
class ChatMessagePage extends StatefulWidget {
  const ChatMessagePage({super.key});

  @override
  State<ChatMessagePage> createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('聊天消息页面'))),
      body: Center(child: Text('聊天消息页面')),
    );
  }
}