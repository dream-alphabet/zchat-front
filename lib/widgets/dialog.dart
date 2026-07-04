import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 弹出确认dialog
Future<dynamic> showPromptDialog(
  BuildContext context,
  String content, {
  VoidCallback? onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        content: Text(
          content,
          style: TextStyle(fontSize: 18.sp, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onConfirm != null) {
                onConfirm();
              }
            },
            child: Text(
              '确定',
              style: TextStyle(
                fontSize: 16.sp,
                color: Color.fromRGBO(20, 134, 237, 1),
              ),
            ),
          ),
        ],
      );
    },
  );
}
