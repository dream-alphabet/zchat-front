// 自定义动画
import 'package:flutter/material.dart';

// 从左侧滑入的页面过渡动画
class SlideRightRoute extends PageRouteBuilder {
  // 要前往的页面
  final Widget page;
  // 页面名称
  final String name;

  SlideRightRoute({required this.page, required this.name})
    : super(
        settings: RouteSettings(name: name),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
            child: child,
          );
        },
      );
}
