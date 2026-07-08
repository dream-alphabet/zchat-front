import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart' hide Response;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/pages/chat/widgets/video_preview.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/widgets/dialog.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 聊天消息组件（StatefulWidget）
class ChatMessage extends StatefulWidget {
  // 消息对象
  final ChatMessageRes message;
  // 列表滚动控制器
  final ScrollController scrollController;

  const ChatMessage({
    super.key,
    required this.message,
    required this.scrollController,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  // 用户信息store
  final _userController = Get.find<UserController>();

  // 选中的文本
  String _selectedText = '';

  // SelectableText焦点控制器
  final _textFocusNode = FocusNode();

  // 消息内容GlobalKey
  final _contentKey = GlobalKey();

  // 上下文菜单悬浮覆盖层
  OverlayEntry? _contextMenuOverlay;

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
        key: _contentKey,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.w),
        decoration: BoxDecoration(
          color: _isSelf ? const Color.fromRGBO(20, 134, 237, 1) : Colors.white,
          borderRadius: .circular(8.r),
        ),
        child: SelectableText(
          msg,
          // 不显示系统上下文带单，改为自己的上下文菜单
          contextMenuBuilder: (context, editableTextState) => SizedBox(),
          focusNode: _textFocusNode,
          onSelectionChanged: (selection, cause) {
            // 如果是长按选中
            if (cause == SelectionChangedCause.longPress) {
              _showContextMenu();
            }
            _selectedText = msg.substring(selection.start, selection.end);
          },
          style: TextStyle(
            color: _isSelf ? Colors.white : Colors.black,
            fontSize: 16.sp,
          ),
        ),
      ),
      color: _isSelf ? const Color.fromRGBO(20, 134, 237, 1) : Colors.white,
    );
  }

  // 构建文件消息
  Widget _buildFileMsg() {
    final fileId = widget.message.fileId ?? -1;
    final fileName = widget.message.fileName ?? '';
    final fileType = widget.message.fileType ?? -1;
    final fileSize = widget.message.fileSize ?? -1;
    // 校验参数
    if (fileId == -1 || fileName.isEmpty || fileType == -1 || fileSize == -1) {
      return _buildTextMsg('文件不存在');
    }
    // 图片
    if (fileType == FileTypeEnum.image.type) {
      return _buildImageMsg(fileId, fileName);
    } else if (fileType == FileTypeEnum.video.type) {
      return _buildVideoMsg(fileId, fileName);
    } else if (fileType == FileTypeEnum.file.type) {
      return _buildNormalFileMsg(fileId, fileName, fileSize);
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
  Widget _buildNormalFileMsg(int fileId, String fileName, int fileSize) {
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
                duration: const Duration(seconds: 2), // 显示时长
              ),
            );
            Navigator.pop(context);
          }),
        ]);
      },
      child: _buildMsgLayout(
        child: Container(
          key: _contentKey,
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
  Widget _buildVideoMsg(int fileId, String fileName) {
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
                  messageId: widget.message.messageId,
                ),
              ),
            );
          },
          child: Hero(
            tag: '$videoUrl-${widget.message.messageId}',
            child: Stack(
              key: _contentKey,
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
  Widget _buildImageMsg(int fileId, String fileName) {
    final imageUrl = _getFileUrl(fileId, fileName);
    return _buildPadding(
      child: Hero(
        tag: '$imageUrl-${widget.message.messageId}',
        child: ConstrainedBox(
          key: _contentKey,
          constraints: BoxConstraints(maxWidth: 200.w, maxHeight: 400.w),
          child: GestureDetector(
            onTap: () {
              _previewImage(imageUrl);
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
  void _saveImageToGallery(String imageUrl) async {
    // 检查相册权限
    final status = await requestGalleryPermission();
    if (status.isDenied) {
      return showPromptDialog(context, '没有权限, 请重试');
    }
    Response<List<int>> response = await Dio().get(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) {
      return ToastUtils.showGlobalToast(msg: '图片获取失败');
    }
    // 将 List<int> 转换为 Uint8List
    Uint8List imageData = Uint8List.fromList(data);
    // 保存到相册
    await Gal.putImageBytes(imageData);
    await ToastUtils.showGlobalToastAsync(msg: '已保存到系统相册');
    Navigator.pop(context);
  }

  // 预览图片
  void _previewImage(String imageUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            onLongPress: () {
              // 显示ActionSheet
              showMyBottomSheet(context, [
                SheetItem('保存到相册', () {
                  _saveImageToGallery(imageUrl);
                }),
              ]);
            },
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(
                tag: '$imageUrl-${widget.message.messageId}',
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
      widget.message.messageContent,
      textAlign: .center,
      style: TextStyle(
        color: const Color.fromRGBO(123, 123, 128, 1),
        fontSize: 16.sp,
      ),
    );
  }

  // 构建个人卡片消息
  Widget _buildPersonCard() {
    final contact = UserContactRes.fromJson(
      jsonDecode(widget.message.data ?? ''),
    );
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RoutePath.contactInfo,
          arguments: {'contactId': contact.contactId},
        );
      },
      child: _buildMsgLayout(
        child: PersonCard(key: _contentKey, contact: contact, type: '个人名片'),
        color: Colors.white,
      ),
    );
  }

  // 构建菜单项
  Widget _buildContextMenuItems(List<ContextMenuItem> items) {
    return Row(
      spacing: 15.w,
      children: List.generate(
        items.length,
        (index) => GestureDetector(
          onTap: items[index].onTap,
          child: Column(
            spacing: 5.w,
            children: [
              Icon(items[index].icon, color: Colors.white, size: 20.sp),
              Text(
                items[index].text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  decoration: .none,
                  fontWeight: .normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建上下文菜单
  Widget _buildContextMenu(List<ContextMenuItem> items, bool topVisible) {
    return CustomPaint(
      painter: ContextMenuArrowPainter(topVisible: topVisible),
      child: Container(
        padding: .all(15.w),
        decoration: BoxDecoration(
          color: Color.fromRGBO(75, 75, 75, 1),
          borderRadius: .circular(8.r),
        ),
        child: _buildContextMenuItems(items),
      ),
    );
  }

  // 关闭上下文菜单
  void _hideContextMenu() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
    _textFocusNode.unfocus();
  }

  // 判断消息内容顶部是否可见
  bool isTopVisible(double dy) {
    return dy > (getStatusBarHeight() + 50.w);
  }

  // 显示上下文菜单
  void _showContextMenu() {
    // 防止重复弹出
    if (_contextMenuOverlay != null) {
      _contextMenuOverlay!.remove();
      _contextMenuOverlay = null;
      return;
    }
    // 获取消息内容元素大侠和在屏幕中的坐标
    final contentBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox;
    Offset offset = contentBox.localToGlobal(Offset.zero);
    Size size = contentBox.size;
    final width = size.width;
    // 上下文菜单项列表
    List<ContextMenuItem> items = [
      if (widget.message.messageType == MessageTypeEnum.text.type)
        ContextMenuItem(
          icon: Icons.copy,
          text: '复制',
          onTap: () async {
            // 将选中的文本复制到剪贴板
            await copyText(_selectedText);
            ToastUtils.showGlobalToast(msg: '已复制');
            _hideContextMenu();
          },
        ),
      ContextMenuItem(
        icon: Icons.share,
        text: '转发',
        onTap: () {
          print('转发');
        },
      ),
      if (_isSelf)
        ContextMenuItem(
          icon: Icons.delete,
          text: '撤回',
          onTap: () {
            print('撤回');
          },
        ),
    ];
    // 上下文菜单水平偏移量: 消息内容宽度的一半-菜单宽度的一半
    final menuWidth = 30.w + 28.sp * items.length + 15.w * (items.length - 1);
    final menuHeight = 32.sp + 35.w;
    final leftOffset = (width / 2) - (menuWidth / 2);
    // 是否顶部可见
    final topVisible = isTopVisible(offset.dy);
    final topOffset = menuHeight + 12.w;
    final top = topVisible
        ? offset.dy - topOffset
        : offset.dy + size.height + 12.w;

    _contextMenuOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 全屏透明点击区，用于点击外部关闭菜单
            GestureDetector(
              onTap: _hideContextMenu,
              behavior: .translucent,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            // 菜单定位
            Positioned(
              left: offset.dx + leftOffset,
              top: top,
              child: _buildContextMenu(items, topVisible),
            ),
          ],
        );
      },
    );

    // 插入覆盖层
    Overlay.of(context).insert(_contextMenuOverlay!);
  }

  // 根据消息类型获取消息内容
  Widget _getContent() {
    // 消息类型
    final messageType = widget.message.messageType;
    // 文本消息
    if (messageType == MessageTypeEnum.text.type) {
      return _buildTextMsg(widget.message.messageContent);
    } else if (messageType == MessageTypeEnum.file.type) {
      // 媒体文件
      return _buildFileMsg();
    } else if (messageType == MessageTypeEnum.systemNotice.type) {
      // 系统通知
      return _buildSystemNotice();
    } else if (messageType == MessageTypeEnum.personCard.type) {
      // 个人卡片
      return _buildPersonCard();
    }
    return _buildTextMsg('未知消息类型');
  }

  // 构建消息内容
  Widget _buildMsgContent() {
    return GestureDetector(
      onTap: _hideContextMenu,
      onLongPress: _showContextMenu,
      child: _getContent(),
    );
  }

  Widget _buildMsg() {
    return Row(
      mainAxisAlignment: _isSelf
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5.w,
      children: _isSelf
          ? [
              Container(
                constraints: BoxConstraints(maxWidth: 240.w),
                child: _buildMsgContent(),
              ),
              // 头像
              ContactAvatar(contactId: widget.message.sendUserId ?? '-1'),
            ]
          : [
              // 头像
              ContactAvatar(contactId: widget.message.sendUserId ?? '-1'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5.w,
                children: [
                  if (widget.message.contactType == UserContactTypeEnum.group)
                    Padding(
                      padding: .only(left: 6.w),
                      child: Text(widget.message.sendUserNickname ?? ''),
                    ),
                  Container(
                    constraints: BoxConstraints(maxWidth: 240.w),
                    child: _buildMsgContent(),
                  ),
                ],
              ),
            ],
    );
  }

  // 是否是当前用户发送的消息
  bool get _isSelf =>
      _userController.userInfo.value?.userId == widget.message.sendUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 10.w, right: 10.w, bottom: 10.w),
      child: widget.message.messageType != MessageTypeEnum.systemNotice.type
          ? _buildMsg()
          : _buildSystemNotice(),
    );
  }

  @override
  void dispose() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
    _textFocusNode.dispose();
    super.dispose();
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

// 上下文菜单三角形绘制器
class ContextMenuArrowPainter extends CustomPainter {
  // 是否顶部可见
  final bool topVisible;

  ContextMenuArrowPainter({required this.topVisible});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromRGBO(75, 75, 75, 1)
      ..style = .fill;

    final path = Path();

    if (topVisible) {
      // 底部添加三角形
      // 移动到三角形顶部
      path.moveTo(size.width / 2, size.height + 10.w);
      path.lineTo(size.width / 2 - 7.w, size.height);
      path.lineTo(size.width / 2 + 7.w, size.height);
    } else {
      // 顶部添加三角形
      path.moveTo(size.width / 2, -10.w);
      path.lineTo(size.width / 2 - 7.w, 0);
      path.lineTo(size.width / 2 + 7.w, 0);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 上下文菜单项
class ContextMenuItem {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  ContextMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });
}
