import 'package:flutter/material.dart';

// 联系人信息(用户/群聊)
class ContactInfoPage extends StatefulWidget {
  const ContactInfoPage({super.key});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  String _userId = '';

  @override
  void initState() { 
    super.initState();
    // 接收用户id参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _userId = params['contactId'];
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('联系人信息(用户/群聊)'))),
      body: Center(child: Text('联系人信息(用户/群聊), 用户id:$_userId')),
    );
  }
}
