import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:video_player/video_player.dart';
import 'package:zchat/common/toast.dart';

// 视频预览组件
class VideoPreview extends StatefulWidget {
  final String videoUrl;

  const VideoPreview({super.key, required this.videoUrl});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _videoController;

  // 用于标记用户是否正在拖动进度条
  bool _isDragging = false;

  // 是否显示控制区域
  bool _showControl = false;

  // 视频进度文本
  String _progressText = '';

  // 当前播放位置
  Duration _currentPosition = Duration.zero;

  // 总播放时长
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..setLooping(false)
          ..initialize().then((_) {
            // 确保视频在初始化之后可以显示第一帧
            setState(() {});
          });
    _videoController.play();
    _videoController.addListener(() {
      // 如果不在拖动进度条，正常更新视频进度
      if (!_isDragging) {
        setState(() {
          _currentPosition = _videoController.value.position;
          _totalDuration = _videoController.value.duration;
          _progressText =
              '${_formatDuration(_currentPosition)}/${_formatDuration(_totalDuration)}';
        });
      }

      // 视频播放完毕
      if (_videoController.value.isCompleted) {
        setState(() {
          _videoController.pause();
        });
      }
    });
  }

  // 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // 播放/暂停按钮
  Widget _buildPlayBtn() {
    return GestureDetector(
      onTap: () {
        // 根据视频状态播放/暂停视频
        setState(() {
          _videoController.value.isPlaying
              ? _videoController.pause()
              : _videoController.play();
        });
      },
      child: Icon(
        _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
        size: 35.w,
      ),
    );
  }

  // 进度条
  Widget _buildProgress() {
    return Expanded(
      child: Stack(
        // 允许子元素超出边界
        clipBehavior: .none,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.w,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.w),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.w),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.4),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.2),
              padding: EdgeInsets.all(0),
            ),
            child: Slider(
              padding: EdgeInsets.all(0),
              value: _currentPosition.inMilliseconds.toDouble().clamp(
                0.0,
                _totalDuration.inMilliseconds.toDouble(),
              ),
              max: _totalDuration.inMilliseconds.toDouble(),
              onChangeStart: (value) {
                print('开始拖动进度条, value: $value');
                // 暂停视频播放
                setState(() {
                  if (!_isDragging) {
                    setState(() => _isDragging = true);
                  }
                  _videoController.pause();
                });
              },
              onChanged: (value) {
                print('正在拖动进度条, value: $value');
                setState(() {
                  // 更新当前进度
                  _currentPosition = Duration(milliseconds: value.toInt());
                  _progressText =
                      '${_formatDuration(_currentPosition)}/${_formatDuration(_totalDuration)}';
                  _videoController.seekTo(
                    Duration(milliseconds: value.toInt()),
                  );
                });
              },
              onChangeEnd: (value) {
                print('结束拖动进度条, value: $value');
                _videoController.seekTo(Duration(milliseconds: value.toInt()));
                setState(() {
                  _isDragging = false;
                  _progressText =
                      '${_formatDuration(_currentPosition)}/${_formatDuration(_totalDuration)}';
                  _videoController.play();
                });
              },
            ),
          ),
          if (!_isDragging)
            Positioned(
              top: -18.w,
              left: 0,
              child: Text(
                _progressText,
                style: TextStyle(fontSize: 14.sp, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // 保存视频到相册
  void _saveVideoToGallery() async {
    final videoPath = '${Directory.systemTemp.path}/video.mp4';
    await Dio().download(widget.videoUrl,videoPath);
    await Gal.putVideo(videoPath);
    ToastUtils.showGlobalToast(msg: '已保存到系统相册');
  }

  // 构建功能区域
  Widget _buildFunction() {
    return Column(
      spacing: 5.w,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPlayBtn(),
            SizedBox(width: 6.w),
            _buildProgress(),
          ],
        ),
        Row(
          spacing: 15.w,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildFunctionItem(Icons.share_sharp, () {
              print('分享');
            }),
            _buildFunctionItem(Icons.save_alt_sharp, _saveVideoToGallery),
          ],
        ),
      ],
    );
  }

  // 构建功能列表项
  Widget _buildFunctionItem(IconData icon, GestureTapCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: Color.fromRGBO(53, 53, 53, 1),
          borderRadius: .circular(15.w),
        ),
        alignment: .center,
        child: Icon(
          icon,
          color: Colors.white,
          size: 18.w,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.light, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Hero(
              tag: widget.videoUrl,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControl = !_showControl;
                  });
                },
                child: Center(
                  child: _videoController.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController.value.aspectRatio,
                          child: VideoPlayer(_videoController),
                        )
                      : SizedBox(),
                ),
              ),
            ),
            // 拖动时，居中显示视频进度
            if (_isDragging)
              Center(
                child: Text(
                  _progressText,
                  style: TextStyle(fontSize: 18.sp, color: Colors.white),
                ),
              ),
            // 关闭按钮
            if (_showControl)
              Positioned(
                top: 20.w,
                left: 20.w,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(53, 53, 53, 1),
                      borderRadius: .circular(20.w),
                    ),
                    alignment: .center,
                    child: Icon(
                      Icons.close_outlined,
                      color: Colors.white,
                      size: 30.w,
                    ),
                  ),
                ),
              ),
            // 功能区域
            if (_showControl)
              Positioned(
                left: 20.w,
                right: 20.w,
                bottom: 20.w,
                child: _buildFunction(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }
}
