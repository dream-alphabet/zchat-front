import 'package:flutter/material.dart';

// 群备注
class GroupRemarkPage extends StatefulWidget {
  const GroupRemarkPage({super.key});

  @override
  State<GroupRemarkPage> createState() => _GroupRemarkPageState();
}

class _GroupRemarkPageState extends State<GroupRemarkPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('群备注'))),
      body: Center(
        child: Text('群备注'),
      ),
    );
  }
}