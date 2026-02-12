import 'package:flutter/material.dart';

// 好友设置
class FriendSettingPage extends StatefulWidget {
  const FriendSettingPage({super.key});

  @override
  State<FriendSettingPage> createState() => _FriendSettingPageState();
}

class _FriendSettingPageState extends State<FriendSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('好友设置'))),
      body: Center(child: Text('好友设置')),
    );
  }
}