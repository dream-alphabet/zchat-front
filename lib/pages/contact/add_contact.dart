import 'package:flutter/material.dart';

// 添加到通讯录
class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('添加到通讯录'))),
      body: Center(child: Text('添加到通讯录')),
    );
  }
}