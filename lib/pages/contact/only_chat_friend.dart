import 'package:flutter/material.dart';

// 仅聊天的朋友
class OnlyChatFriendPage extends StatefulWidget {
  const OnlyChatFriendPage({super.key});

  @override
  State<OnlyChatFriendPage> createState() => _OnlyChatFriendPageState();
}

class _OnlyChatFriendPageState extends State<OnlyChatFriendPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('仅聊天的朋友'))),
      body: Center(child: Text('仅聊天的朋友')),
    );
  }
}
