import 'package:flutter/material.dart';

// 新的朋友
class NewFriendPage extends StatefulWidget {
  const NewFriendPage({super.key});

  @override
  State<NewFriendPage> createState() => _NewFriendPageState();
}

class _NewFriendPageState extends State<NewFriendPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('新的朋友'))),
      body: Center(child: Text('新的朋友')),
    );
  }
}
