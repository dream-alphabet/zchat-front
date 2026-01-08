import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// base64图片
class Base64Image extends StatelessWidget {
  final String base64String;
  final void Function() onRefreshCaptcha;

  const Base64Image({
    super.key,
    required this.base64String,
    required this.onRefreshCaptcha,
  });

  @override
  Widget build(BuildContext context) {
    if (base64String.isEmpty) {
      return _buildErrorWidget();
    }
    // 移除可能的 data:image/...;base64, 前缀
    final String data = base64String.contains(',')
        ? base64String.split(',').last
        : base64String;

    try {
      final Uint8List bytes = base64.decode(data);
      return GestureDetector(
        onTap: onRefreshCaptcha,
        child: Image.memory(
          bytes,
          width: 100.w,
          height: 48.w,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      // 解码失败时显示占位图
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return GestureDetector(
      onTap: onRefreshCaptcha,
      child: Container(
        color: Colors.grey[200],
        child: Icon(Icons.broken_image, color: Colors.grey[400]),
      ),
    );
  }
}
