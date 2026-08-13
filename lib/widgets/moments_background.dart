import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/constants.dart';

// 朋友圈背景组件（未上传时显示默认深色背景+提示文案）
class MomentsBackground extends StatefulWidget {
  final String userId;
  // 背景未上传时显示的居中提示文案
  final String? hintText;
  // 背景版本号，用于强制刷新缓存（每次修改背景+1）
  final int version;
  // Hero动画tag（为空时不启用Hero）
  final String? heroTag;
  // 背景加载状态回调(true=有背景图, false=未上传)
  final ValueChanged<bool>? onStateChanged;

  const MomentsBackground({
    super.key,
    required this.userId,
    this.hintText,
    this.version = 0,
    this.heroTag,
    this.onStateChanged,
  });

  @override
  State<MomentsBackground> createState() => _MomentsBackgroundState();
}

class _MomentsBackgroundState extends State<MomentsBackground> {
  // 背景图片是否加载成功
  bool _loaded = false;

  // 背景图片地址（带版本参数，避免修改后缓存不刷新）
  String get url =>
      '${GlobalConstants.momentsBackgroundUrl}/${widget.userId}.jpg?v=${widget.version}';

  // 通知父组件加载状态（延迟到帧结束，避免build期间setState）
  void _notifyState(bool loaded) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onStateChanged?.call(loaded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 默认深色渐变背景（图片加载失败或未上传时可见）
        Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(87, 87, 87, 1),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(87, 87, 87, 1),
                Colors.black.withOpacity(0.8),
              ],
              stops: [0.9, 1.0],
            ),
          ),
          child: widget.hintText == null
              ? null
              : Center(
                  child: Text(
                    widget.hintText!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color.fromRGBO(134, 134, 134, 1),
                    ),
                  ),
                ),
        ),
        // 背景图片（加载失败时不显示，露出默认背景）
        Hero(
          tag: widget.heroTag ?? 'unused',
          child: Image.network(
            url,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              final success = wasSynchronouslyLoaded || frame != null;
              if (success != _loaded) {
                _loaded = success;
                _notifyState(success);
              }
              return child;
            },
            errorBuilder: (_, _, _) {
              if (_loaded) {
                _loaded = false;
                _notifyState(false);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
