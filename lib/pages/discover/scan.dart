import 'package:flutter/material.dart';

// 扫一扫
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('扫一扫'))),
      body: Center(child: Text('扫一扫')),
    );
  }
}
