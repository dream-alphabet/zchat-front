import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 微信风格开关
class WeChatSwitch extends StatelessWidget {
  // 开关状态
  final bool value;
  // 状态变化回调
  final ValueChanged<bool> onChanged;

  // 开关颜色
  static const _activeColor = Color.fromRGBO(20, 134, 237, 1); // 微信绿
  static const _inactiveColor = Color.fromRGBO(233, 233, 234, 1); // 关闭灰

  const WeChatSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 51.w,
        height: 31.w,
        decoration: BoxDecoration(
          color: value ? _activeColor : _inactiveColor,
          borderRadius: BorderRadius.circular(31.w / 2),
        ),
        child: Padding(
          padding: EdgeInsets.all(2.w),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 27.w,
              height: 27.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
