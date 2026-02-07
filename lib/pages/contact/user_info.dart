import 'package:flutter/material.dart';

// 用户信息
class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  String _userId = '';

  @override
  void initState() { 
    super.initState();
    // 接收用户id参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _userId = params['userId'];
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('用户信息'))),
      body: Center(child: Text('用户信息, 用户id:$_userId')),
    );
  }
}
