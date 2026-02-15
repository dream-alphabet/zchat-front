import 'package:flutter/material.dart';

// 验证联系人申请
class VerifyApplyPage extends StatefulWidget {
  const VerifyApplyPage({super.key});

  @override
  State<VerifyApplyPage> createState() => _VerifyApplyPageState();
}

class _VerifyApplyPageState extends State<VerifyApplyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('验证联系人申请'))),
      body: Center(child: Text('验证联系人申请')),
    );
  }
}