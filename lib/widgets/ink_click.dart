import 'package:flutter/material.dart';

// 带有涟漪特效的点击
class InkClick extends StatelessWidget {
  // 子组件
  final Widget child;
  // 点击事件
  final GestureTapCallback? onTap;
  // 背景颜色
  final Color backgroundColor;

  const InkClick({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
