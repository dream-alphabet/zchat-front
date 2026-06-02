import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:zchat/routes/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 全局Toast工具类
class ToastUtils {
  static late FToast _fToast;
  static bool _isShow = false;

  // 初始化全局 FToast
  static void init() {
    _fToast = FToast();
    // 使用全局上下文初始化
    _fToast.init(globalNavigatorKey.currentContext!);
  }

  // 显示全局Toast
  static void showGlobalToast({
    required String msg,
    Duration duration = const Duration(seconds: 1),
  }) {
    // 如果已经有toast正在显示
    if (_isShow) {
      return;
    }
    _isShow = true;
    Widget toast = Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(msg, style: TextStyle(color: Colors.white)),
    );
    _fToast.showToast(
      child: toast,
      gravity: ToastGravity.CENTER,
      toastDuration: duration,
    );
    Future.delayed(duration, () {
      _isShow = false;
    });
  }

  // 显示全局Toast(Future版), 返回值为是否真的弹出了toast
  static Future<bool> showGlobalToastAsync({
    required String msg,
    Duration duration = const Duration(seconds: 1),
  }) async {
    // 如果已经有toast正在显示
    if (_isShow) {
      return false;
    }
    _isShow = true;
    Widget toast = Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(msg, style: TextStyle(color: Colors.white)),
    );
    _fToast.showToast(
      child: toast,
      gravity: ToastGravity.CENTER,
      toastDuration: duration,
    );
    await Future.delayed(duration, () {
      _isShow = false;
    });
    return true;
  }
}
