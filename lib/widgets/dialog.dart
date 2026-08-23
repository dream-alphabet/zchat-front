import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 弹出内容dialog(查看完整文本)
Future<void> showContentDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(fontSize: 15.sp, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '关闭',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color.fromRGBO(20, 134, 237, 1),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// 弹出确认dialog
Future<bool?> showPromptDialog(
  BuildContext context,
  String content, {
  bool showCancel = false,
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
  String confirmText = '确定'
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        content: Text(
          content,
          style: TextStyle(fontSize: 18.sp, color: Colors.black),
        ),
        actions: [
          if (showCancel)
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              if (onCancel != null) {
                onCancel();
              }
            },
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              if (onConfirm != null) {
                onConfirm();
              }
            },
            child: Text(
              confirmText,
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color.fromRGBO(20, 134, 237, 1),
              ),
            ),
          ),
        ],
      );
    },
  );
}
