import 'package:flutter/material.dart';

// 主页
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: Center(
        child: Text('主页'),
       ),
    );
  }
}