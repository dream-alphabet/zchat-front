import 'package:flutter/material.dart';

// 我的二维码
class MyQrcodePage extends StatefulWidget {
  const MyQrcodePage({super.key});

  @override
  State<MyQrcodePage> createState() => _MyQrcodePageState();
}

class _MyQrcodePageState extends State<MyQrcodePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('我的二维码'))),
      body: Center(child: Text('我的二维码')),
    );
  }
}