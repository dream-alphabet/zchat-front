import 'package:flutter/material.dart';

// 朋友圈
class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('朋友圈'))),
      body: Center(child: Text('朋友圈')),
    );
  }
}
