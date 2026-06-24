import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/constants.dart';

// 头像修改全局监听
class AvatarGlobal {
  static final Map<String, ValueNotifier<int>> _versionNotifiers = {};

  // 获取对应的监听
  static ValueNotifier<int> getNotifier(String contactId) {
    return _versionNotifiers.putIfAbsent(
      contactId,
      () => ValueNotifier<int>(0),
    );
  }

  static Future<void> refresh(String contactId) async {
    await NetworkImage('${GlobalConstants.avatarUrl}/$contactId.jpg').evict();
    getNotifier(contactId).value++; // 触发监听
  }
}

// 联系人(用户/群聊)头像组件
class ContactAvatar extends StatelessWidget {
  final String contactId;
  final int size;
  // 头像形状，默认圆形
  final BoxShape shape;

  const ContactAvatar({
    super.key,
    required this.contactId,
    this.size = 40,
    this.shape = .circle,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AvatarGlobal.getNotifier(contactId),
      builder: (ctx, version, child) {
        return ClipRRect(
          borderRadius: .circular(
            shape == BoxShape.circle ? (size / 2).r : 5.r,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            '${GlobalConstants.avatarUrl}/$contactId.jpg',
            key: ValueKey('avatar_$contactId$version'),
            width: size.w,
            height: size.w,
            errorBuilder: (context, error, stackTrace) {
              // 用户头像加载失败，使用默认头像
              return Image.asset(
                GlobalConstants.defaultAvatar,
                key: ValueKey('avatar_$contactId$version'),
                width: size.w,
                height: size.w,
              );
            },
          ),
        );
      },
    );
  }
}
