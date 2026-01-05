import 'package:flutter/material.dart';

// 分享
class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: Center(
        child: Text('分享'),
       ),
    );
  }
}