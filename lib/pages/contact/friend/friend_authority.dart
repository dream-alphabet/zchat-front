import 'package:flutter/material.dart';

// 好友权限
class FriendAuthorityPage extends StatefulWidget {
  const FriendAuthorityPage({super.key});

  @override
  State<FriendAuthorityPage> createState() => _FriendAuthorityPageState();
}

class _FriendAuthorityPageState extends State<FriendAuthorityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('好友权限')),
      body: Center(child: Text('好友权限')),
    );
  }
}
