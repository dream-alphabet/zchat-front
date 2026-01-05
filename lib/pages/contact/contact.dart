import 'package:flutter/material.dart';

// 联系人
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: Center(
        child: Text('联系人'),
       ),
    );
  }
}