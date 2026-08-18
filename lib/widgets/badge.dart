import 'package:flutter/material.dart';

// 未读消息badge
class UnreadCountBadge extends StatelessWidget {
  // 未读消息数量
  final int count;
  // 是否免打扰(免打扰只显示红点，不显示数字)
  final bool disturb;
  // 子组件
  final Widget child;

  const UnreadCountBadge({
    super.key,
    required this.count,
    required this.child,
    this.disturb = false,
  });

  @override
  Widget build(BuildContext context) {
    // 免打扰：只显示小圆点
    if (disturb) {
      return Badge(
        smallSize: 10,
        isLabelVisible: count > 0,
        child: child,
      );
    }
    return Badge(
      label: Text('${count > 99 ? '99+' : count}'),
      isLabelVisible: count > 0,
      child: child,
    );
  }
}
