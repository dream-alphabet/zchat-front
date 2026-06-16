// 自定义动画
import 'package:flutter/material.dart';

// 从左侧滑入的页面过渡动画
class SlideRightRoute extends PageRouteBuilder {
  // 要前往的页面
  final Widget page;

  SlideRightRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.ease)).animate(animation),
            child: child,
          );
        },
      );
}
