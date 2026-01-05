import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/widgets/page_header.dart';

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
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(title: '通讯录'),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 10.w),
            child: Center(child: Text('联系人列表')),
          ),
        ],
      ),
    );
  }
}
