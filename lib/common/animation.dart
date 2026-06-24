// 自定义动画
import 'package:flutter/material.dart';

// 页面自定义动画工具类
class RouteUtils {
  // 从底部向上滑入
  static Route<T> slideUp<T>(
    WidgetBuilder builder, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: 400)
    );
  }

  // 从左侧滑入
  static Route<T> slideRight<T>(
    WidgetBuilder builder, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: 400)
    );
  }
}
