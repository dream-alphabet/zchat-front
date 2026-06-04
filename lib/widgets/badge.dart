import 'package:flutter/material.dart';

// 未读消息badge
class UnreadCountBadge extends StatelessWidget {
  // 未读消息数量
  final int count;
  // 子组件
  final Widget child;

  const UnreadCountBadge({super.key, required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: Text('${count > 99 ? '99+' : count}'),
      isLabelVisible: count > 0,
      child: child,
    );
  }
}
