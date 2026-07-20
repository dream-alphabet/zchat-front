import 'package:flutter/material.dart';

// 群二维码
class GroupQrcodePage extends StatefulWidget {
  const GroupQrcodePage({super.key});

  @override
  State<GroupQrcodePage> createState() => _GroupQrcodePageState();
}

class _GroupQrcodePageState extends State<GroupQrcodePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('群二维码'))),
      body: Center(
        child: Text('群二维码'),
      ),
    );
  }
}