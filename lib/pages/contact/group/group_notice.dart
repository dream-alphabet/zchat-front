import 'package:flutter/material.dart';

// 群公告
class GroupNoticePage extends StatefulWidget {
  const GroupNoticePage({super.key});

  @override
  State<GroupNoticePage> createState() => _GroupNoticePageState();
}

class _GroupNoticePageState extends State<GroupNoticePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('群公告'))),
      body: Center(
        child: Text('群公告'),
      ),
    );
  }
}