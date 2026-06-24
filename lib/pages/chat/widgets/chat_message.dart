import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/pages/chat/widgets/video_preview.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 聊天消息组件
class ChatMessage extends StatelessWidget {
  // 消息对象
  final ChatMessageRes message;

  // 用户信息store
  final _userController = Get.find<UserController>();

  ChatMessage({super.key, required this.message});

  // 消息通用边距
  Widget _buildPadding({required Widget child}) {
    return Padding(
      padding: _isSelf
          ? EdgeInsets.only(right: 6.w)
          : EdgeInsets.only(left: 6.w),
      child: child,
    );
  }

  // 构建消息框架
  Widget _buildMsgLayout({required Widget child, required Color color}) {
    return _buildPadding(
      child: CustomPaint(
        painter: BubbleArrowPainter(isSelf: _isSelf, color: color),
        child: child,
      ),
    );
  }

  // 构建文本消息
  Widget _buildTextMsg(String msg) {
    return _buildMsgLayout(
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
      color: _isSelf ? Color.fromRGBO(20, 134, 237, 1) : Colors.white,
    );
  }

  // 构建文件消息
  Widget _buildFileMsg(BuildContext context) {
    final fileId = message.fileId ?? -1;
    final fileName = message.fileName ?? '';
    final fileType = message.fileType ?? -1;
    final fileSize = message.fileSize ?? -1;
    // 校验参数
    if (fileId == -1 || fileName.isEmpty || fileType == -1 || fileSize == -1) {
      return _buildTextMsg('文件不存在');
    }
    // 图片
    if (fileType == FileTypeEnum.image.type) {
      return _buildImageMsg(context, fileId, fileName);
    } else if (fileType == FileTypeEnum.video.type) {
      return _buildVideoMsg(context, fileId, fileName);
    } else if (fileType == FileTypeEnum.file.type) {
      return _buildNormalFileMsg(context, fileId, fileName, fileSize);
    }
    return _buildTextMsg('未知文件类型');
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      double kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      double mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      double gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }

  // 构建普通文件消息
  Widget _buildNormalFileMsg(
    BuildContext context,
    int fileId,
    String fileName,
    int fileSize,
  ) {
    return GestureDetector(
      onTap: () {
        showMyBottomSheet(context, [
          SheetItem('保存到本地', () async {
            final dir = await getDownloadsDirectory();
            final fileUrl = _getFileUrl(fileId, fileName);
            final savePath = '${dir?.path ?? '/Downloads'}/zchat_app/$fileName';
            print('已保存到: $savePath');
            await Dio().download(fileUrl, savePath);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已保存到: $savePath'),
                duration: Duration(seconds: 2), // 显示时长
              ),
            );
            Navigator.pop(context);
          }),
        ]);
      },
      child: _buildMsgLayout(
        child: Container(
          width: 240.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: .circular(5.r),
            color: Colors.white,
          ),
          child: Row(
            spacing: 10.w,
            crossAxisAlignment: .center,
            children: [
              Expanded(
                child: Column(
                  spacing: 5.w,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        overflow: .ellipsis,
                      ),
                    ),
                    Text(
                      _formatFileSize(fileSize),
                      style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
              Icon(MyIcon.fileMsg, color: Colors.black, size: 50.w),
            ],
          ),
        ),
        color: Colors.white,
      ),
    );
  }

  // 构建视频消息
  Widget _buildVideoMsg(BuildContext context, int fileId, String fileName) {
    // 视频url
    final videoUrl = _getFileUrl(fileId, fileName);
    // 封面url
    final coverUrl = _getFileUrl(fileId, fileName, isCover: true);
    return _buildPadding(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 200.w, maxHeight: 400.w),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => VideoPreview(
                  videoUrl: videoUrl,
                  messageId: message.messageId,
                ),
              ),
            );
          },
          child: Hero(
            tag: '$videoUrl-${message.messageId}',
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
    return _buildPadding(
      child: Hero(
        tag: '$imageUrl-${message.messageId}',
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
              heroAttributes: PhotoViewHeroAttributes(
                tag: '$imageUrl-${message.messageId}',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建系统通知消息
  Widget _buildSystemNotice() {
    return Text(
      message.messageContent,
      textAlign: .center,
      style: TextStyle(
        color: Color.fromRGBO(123, 123, 128, 1),
        fontSize: 16.sp,
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
      // 媒体文件
      return _buildFileMsg(context);
    } else if (messageType == MessageTypeEnum.systemNotice.type) {
      // 系统通知
      return _buildSystemNotice();
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
      child: message.messageType != MessageTypeEnum.systemNotice.type
          ? Row(
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
                      ContactAvatar(contactId: message.sendUserId ?? '-1'),
                    ]
                  : [
                      // 头像
                      ContactAvatar(contactId: message.sendUserId ?? '-1'),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5.w,
                        children: [
                          if (message.contactType == UserContactTypeEnum.group)
                            Padding(
                              padding: .only(left: 6.w),
                              child: Text(message.sendUserNickname ?? ''),
                            ),
                          Container(
                            constraints: BoxConstraints(maxWidth: 240.w),
                            child: _buildMsgContent(context),
                          ),
                        ],
                      ),
                    ],
            )
          : _buildSystemNotice(),
    );
  }
}

// 消息气泡左/右侧箭头绘制器
class BubbleArrowPainter extends CustomPainter {
  final bool isSelf;
  final Color color;

  BubbleArrowPainter({required this.isSelf, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
