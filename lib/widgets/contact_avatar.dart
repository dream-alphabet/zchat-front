import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 联系人(用户/群聊)头像组件
class ContactAvatar extends StatelessWidget {
  final String imageUrl;
  final int size;

  const ContactAvatar({super.key, required this.imageUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.w),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(imageUrl, width: size.w, height: size.w),
    );
  }
}
