import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/routes/index.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 全局消息提示类
class MessageUtils {
  // 用于插入到overlay悬浮层的entry
  static OverlayEntry? _currentEntry;
  // 是否有消息正在显示
  static bool _isShowing = false;

  // 显示全局消息
  static void show({
    required String msg,
    required String contactId,
    required String contactName,
    required int sendTime,
    Duration duration = const Duration(milliseconds: 1500),
    GestureTapCallback? onTap,
  }) {
    // 有消息正在显示，删除旧entry，显示新消息
    if (_isShowing) {
      _currentEntry?.remove();
      _currentEntry = null;
    }
    _isShowing = true;
    final overlay = globalNavigatorKey.currentState?.overlay;
    // 没有悬浮层, 无法显示消息
    if (overlay == null) return;
    // 创建entry(消息提示本体)
    _currentEntry = OverlayEntry(
      builder: (ctx) => _MessageOverlay(
        sendTime: sendTime,
        contactId: contactId,
        contactName: contactName,
        message: msg,
        onTap: () {
          // 如果传递了点击事件
          if (onTap != null) {
            onTap();
            hide();
          }
        },
      ),
    );
    // 将entry插入悬浮层
    overlay.insert(_currentEntry!);
    // 指定时间后隐藏
    Future.delayed(duration, hide);
  }

  // 隐藏全局消息
  static void hide() {
    if (_isShowing && _currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
      _isShowing = false;
    }
  }
}

// 全局消息遮罩
class _MessageOverlay extends StatefulWidget {
  final String message;
  final String contactId;
  final String contactName;
  final int sendTime;
  final GestureTapCallback? onTap;
  const _MessageOverlay({
    required this.message,
    required this.contactId,
    required this.contactName,
    required this.sendTime,
    this.onTap,
  });

  @override
  State<_MessageOverlay> createState() => _MessageOverlayState();
}

class _MessageOverlayState extends State<_MessageOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // 从屏幕上方外开始
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20.w,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: SafeArea(
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: EdgeInsets.all(10.w),
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                spacing: 10.w,
                crossAxisAlignment: .start,
                children: [
                  // 头像
                  ContactAvatar(imageUrl: 'lib/assets/test/01.png'),
                  // 内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          widget.contactName,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                            fontWeight: .normal,
                            decoration: .none,
                          ),
                        ),
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                            fontWeight: .normal,
                            decoration: .none,
                            overflow: .ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 时间
                  Text(
                    formatTimestamp(widget.sendTime),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontWeight: .normal,
                      decoration: .none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
