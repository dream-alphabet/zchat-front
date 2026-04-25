import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/pages/chat/widgets/video_preview.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/widgets/bottom_sheet.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 聊天消息组件
class ChatMessage extends StatelessWidget {
  // 消息对象
  final ChatMessageRes message;

  // 用户信息store
  final _userController = Get.find<UserController>();

  ChatMessage({super.key, required this.message});

  // 构建文本消息
  Widget _buildTextMsg(String msg) {
    return Padding(
      padding: _isSelf
          ? EdgeInsets.only(right: 6.w)
          : EdgeInsets.only(left: 6.w),
      child: CustomPaint(
        painter: BubbleArrowPainter(isSelf: _isSelf),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.w),
          decoration: BoxDecoration(
            color: _isSelf ? Color.fromRGBO(20, 134, 237, 1) : Colors.white,
            borderRadius: .circular(8.r),
          ),
          child: SelectableText(
            msg,
            style: TextStyle(
              color: _isSelf ? Colors.white : Colors.black,
              fontSize: 16.sp,
            ),
          ),
        ),
      ),
    );
  }

  // 构建文件消息
  Widget _buildFileMsg(BuildContext context) {
    final fileId = message.fileId ?? -1;
    final fileName = message.fileName ?? '';
    final fileType = message.fileType ?? -1;
    // 校验参数
    if (fileId == -1 || fileName.isEmpty || fileType == -1) {
      return _buildTextMsg('文件不存在');
    }
    // 图片
    if (fileType == FileTypeEnum.image.type) {
      return _buildImageMsg(context, fileId, fileName);
    } else if (fileType == FileTypeEnum.video.type) {
      return _buildVideoMsg(context, fileId, fileName);
    }
    return _buildTextMsg('未知文件类型');
  }

  // 构建视频消息
  Widget _buildVideoMsg(BuildContext context, int fileId, String fileName) {
    // 视频url
    final videoUrl = _getFileUrl(fileId, fileName);
    // 封面url
    final coverUrl = _getFileUrl(fileId, fileName, isCover: true);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 200.w, maxHeight: 400.w),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => VideoPreview(videoUrl: videoUrl),
            ),
          );
        },
        child: Hero(
          tag: videoUrl,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: .circular(8.r),
                child: Image.network(
                  coverUrl,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (ctx, _, _) => Container(
                    width: 200.w,
                    height: 200.w,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: .circular(8.r),
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: 50.w,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 获取文件访问url
  String _getFileUrl(int fileId, String fileName, {bool isCover = false}) {
    // 文件访问url
    var fileUrl = '${GlobalConstants.msgFileUrl}/$fileId';
    if (isCover) {
      fileUrl += "_cover.jpg";
    } else {
      // 如果有后缀名
      final index = fileName.lastIndexOf(".");
      if (index != -1) {
        fileUrl += fileName.substring(index);
      }
    }
    return fileUrl;
  }

  // 构建图片消息
  Widget _buildImageMsg(BuildContext context, int fileId, String fileName) {
    final imageUrl = _getFileUrl(fileId, fileName);
    return Hero(
      tag: imageUrl,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 200.w, maxHeight: 400.w),
        child: GestureDetector(
          onTap: () {
            _previewImage(context, imageUrl);
          },
          child: ClipRRect(
            borderRadius: .circular(8.r),
            child: Image.network(imageUrl, fit: BoxFit.fitWidth),
          ),
        ),
      ),
    );
  }

  // 保存到相册
  void _saveImageToGallery(BuildContext context, String imageUrl) async {
    final imagePath = '${Directory.systemTemp.path}/image.jpg';
    await Dio().download(imageUrl, imagePath);
    await Gal.putImage(imagePath);
    ToastUtils.showGlobalToastAsync(msg: '已保存到系统相册').then((_) {
      Navigator.pop(context);
    });
  }

  // 预览图片
  void _previewImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
            },
            onLongPress: () {
              // 显示ActionSheet
              showMyBottomSheet(context, [
                SheetItem('保存到相册', () {
                  _saveImageToGallery(context, imageUrl);
                }),
              ]);
            },
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  // 构建消息内容
  Widget _buildMsgContent(BuildContext context) {
    // 消息类型
    final messageType = message.messageType;
    // 文本消息
    if (messageType == MessageTypeEnum.text.type) {
      return _buildTextMsg(message.messageContent);
    } else if (messageType == MessageTypeEnum.file.type) {
      return _buildFileMsg(context);
    }
    return _buildTextMsg('未知消息类型');
  }

  // 是否是当前用户发送的消息
  bool get _isSelf =>
      _userController.userInfo.value?.userId == message.sendUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 10.w, right: 10.w, bottom: 10.w),
      child: Row(
        mainAxisAlignment: _isSelf
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.w,
        children: _isSelf
            ? [
                Container(
                  constraints: BoxConstraints(maxWidth: 240.w),
                  child: _buildMsgContent(context),
                ),
                // 头像
                ContactAvatar(imageUrl: 'lib/assets/test/01.png'),
              ]
            : [
                // 头像
                ContactAvatar(imageUrl: 'lib/assets/test/01.png'),
                Container(
                  constraints: BoxConstraints(maxWidth: 240.w),
                  child: _buildMsgContent(context),
                ),
              ],
      ),
    );
  }
}

// 文本消息气泡左侧箭头绘制器
class BubbleArrowPainter extends CustomPainter {
  final bool isSelf;

  BubbleArrowPainter({required this.isSelf});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelf ? Color.fromRGBO(20, 134, 237, 1) : Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isSelf) {
      // 绘制右侧小三角形箭头
      path.moveTo(size.width + 6.w, 12.w); // 起点
      path.lineTo(size.width, 7.w);
      path.lineTo(size.width, 17.w);
    } else {
      // 绘制左侧小三角形箭头
      path.moveTo(-6.w, 12.w); // 起点
      path.lineTo(0, 7.w);
      path.lineTo(0, 17.w);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
