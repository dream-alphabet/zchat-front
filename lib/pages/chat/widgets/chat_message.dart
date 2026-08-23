import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart' hide Response;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/common/animation.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/common/voice_player.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/pages/chat/widgets/video_preview.dart';
import 'package:zchat/pages/contact/contact_select.dart';
import 'package:zchat/pages/chat/chat_record_detail.dart';
import 'package:zchat/stores/session.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/widgets/dialog.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 解析聊天记录快照(失败返回null)
List<ChatMessageRes>? parseChatRecordSnapshot(String? data) {
  if (data == null || data.isEmpty) {
    return null;
  }
  try {
    final messages = jsonDecode(data)['messages'] as List?;
    if (messages == null || messages.isEmpty) {
      return null;
    }
    final result = <ChatMessageRes>[];
    for (var i = 0; i < messages.length; i++) {
      try {
        final map = messages[i] as Map<String, dynamic>;
        result.add(ChatMessageRes(
          // messageId用索引保证详情页内唯一(语音互斥/图片Hero tag依赖唯一id)
          messageId: i,
          sessionId: '',
          messageType: (map['messageType'] as num?)?.toInt() ?? -1,
          messageContent: map['messageContent'] ?? '',
          sendUserId: map['sendUserId'] as String?,
          sendUserNickname: map['sendUserNickname'] as String?,
          sendTime: (map['sendTime'] as num?)?.toInt() ?? 0,
          contactId: '',
          contactName: '',
          contactType: 0,
          fileId: (map['fileId'] as num?)?.toInt(),
          fileName: map['fileName'] as String?,
          fileType: (map['fileType'] as num?)?.toInt(),
          fileSize: (map['fileSize'] as num?)?.toInt(),
          status: MessageStatusEnum.sent.status,
          data: map['data'] as String?,
        ));
      } catch (_) {
        // 跳过坏条目
      }
    }
    return result.isEmpty ? null : result;
  } catch (_) {
    return null;
  }
}

// 消息内容摘要(聊天记录卡片预览用)
String messageContentPreview(ChatMessageRes message) {
  final type = message.messageType;
  if (type == MessageTypeEnum.text.type) {
    return message.messageContent;
  } else if (type == MessageTypeEnum.file.type) {
    if (message.fileType == FileTypeEnum.image.type) {
      return '[图片]';
    } else if (message.fileType == FileTypeEnum.video.type) {
      return '[视频]';
    }
    return '[文件]${message.fileName ?? ''}';
  } else if (type == MessageTypeEnum.personCard.type) {
    return '[名片]';
  } else if (type == MessageTypeEnum.voice.type) {
    return '[语音]';
  } else if (type == MessageTypeEnum.chatRecord.type) {
    return '[聊天记录]';
  } else if (type == MessageTypeEnum.videoCall.type ||
      type == MessageTypeEnum.voiceCall.type) {
    final data = message.data;
    if (data != null && data.isNotEmpty) {
      try {
        final duration = jsonDecode(data)['duration'];
        if (duration != null) {
          return '通话时长 ${formatDuration(duration)}';
        }
      } catch (_) {}
    }
    return message.messageContent;
  }
  return message.messageContent;
}

// 聊天消息组件（StatefulWidget）
class ChatMessage extends StatefulWidget {
  // 消息对象
  final ChatMessageRes message;
  // 列表滚动控制器
  final ScrollController scrollController;
  // 转发消息事件
  final void Function(ChatMessageRes, UserContactRes) onShareMessage;
  // 语音/视频通话事件
  final void Function(MessageTypeEnum) onVideoOrVoiceCall;
  // 是否多选模式
  final bool multiSelectMode;
  // 是否已选中(多选模式)
  final bool selected;
  // 多选模式下点击气泡回调(为null表示该消息不可勾选)
  final VoidCallback? onSelectTap;
  // 菜单"多选"回调
  final VoidCallback? onMultiSelect;
  // 是否显示长按菜单(详情页传false)
  final bool showMenu;

  const ChatMessage({
    super.key,
    required this.message,
    required this.scrollController,
    required this.onShareMessage,
    required this.onVideoOrVoiceCall,
    this.multiSelectMode = false,
    this.selected = false,
    this.onSelectTap,
    this.onMultiSelect,
    this.showMenu = true,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  // 用户信息store
  final _userController = Get.find<UserController>();

  // 会话store
  final sessionStore = Get.find<ChatSessionStore>();

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

  // 构建语音消息
  Widget _buildVoiceMsg() {
    final fileId = widget.message.fileId ?? -1;
    final fileName = widget.message.fileName ?? '';
    // 校验参数
    if (fileId == -1 || fileName.isEmpty) {
      return _buildTextMsg('语音消息不存在');
    }
    // 时长(秒)
    var duration = 0;
    final data = widget.message.data;
    if (data != null && data.isNotEmpty) {
      try {
        duration = (jsonDecode(data)['duration'] as num?)?.toInt() ?? 0;
      } catch (_) {
        // 数据损坏时兜底为0
        duration = 0;
      }
    }
    // 气泡宽度随时长增长(微信风格)
    var width = 60.w + duration * 1.5.w;
    if (width > 170.w) {
      width = 170.w;
    }
    // 语音url
    final voiceUrl = _getFileUrl(fileId, fileName);
    // 语音key(消息id，防止相同文件id的消息互斥失效)
    final voiceKey = '${widget.message.messageId}';
    final bubbleColor = _isSelf
        ? const Color.fromRGBO(20, 134, 237, 1)
        : Colors.white;
    final contentColor = _isSelf ? Colors.white : Colors.black;
    return _buildMsgLayout(
      child: GestureDetector(
        onTap: () {
          unawaited(
            VoicePlayer.instance.play(key: voiceKey, url: voiceUrl),
          );
        },
        child: ValueListenableBuilder<String?>(
          valueListenable: VoicePlayer.instance.playingKey,
          builder: (context, playingKey, _) {
            final playing = playingKey == voiceKey;
            return Container(
              key: _contentKey,
              width: width,
              alignment: _isSelf ? Alignment.centerRight : Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.w),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: .circular(8.r),
              ),
              child: Row(
                mainAxisSize: .min,
                children: [
                  // 喇叭图标在气泡靠近箭头的一侧
                  if (!_isSelf) _buildVoiceIcon(playing, contentColor),
                  if (!_isSelf) SizedBox(width: 6.w),
                  Text(
                    '$duration″',
                    style: TextStyle(color: contentColor, fontSize: 14.sp),
                  ),
                  if (_isSelf) SizedBox(width: 6.w),
                  if (_isSelf) _buildVoiceIcon(playing, contentColor),
                ],
              ),
            );
          },
        ),
      ),
      color: bubbleColor,
    );
  }

  // 语音图标(播放时显示动画)
  Widget _buildVoiceIcon(bool playing, Color color) {
    if (!playing) {
      return Icon(MyIcon.voice, size: 20.w, color: color);
    }
    return _VoicePlayingIcon(color: color);
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
      showPromptDialog(context, '没有权限, 请重试');
      return;
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
  Widget _buildSystemNotice(String text) {
    return Text(
      text,
      textAlign: .center,
      style: TextStyle(
        color: const Color.fromRGBO(123, 123, 128, 1),
        fontSize: 16.sp,
      ),
    );
  }

  // 构建个人卡片消息
  Widget _buildPersonCard() {
    PersonCardData contact;
    try {
      contact = PersonCardData.fromJson(
        jsonDecode(widget.message.data ?? ''),
      );
    } catch (_) {
      // 名片数据损坏时兜底
      return _buildTextMsg('[名片]');
    }
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RoutePath.contactInfo,
          arguments: {'contactId': contact.contactId},
        );
      },
      child: _buildMsgLayout(
        child: PersonCard(
          key: _contentKey,
          contact: contact,
          type: contact.contactType == UserContactTypeEnum.user ? '个人名片' : '群聊',
        ),
        color: Colors.white,
      ),
    );
  }

  // 构建聊天记录消息(合并转发)
  Widget _buildChatRecordMsg() {
    final messages = parseChatRecordSnapshot(widget.message.data);
    final count = messages?.length ?? 0;
    // 第一条消息预览
    String preview = '';
    if (messages != null && messages.isNotEmpty) {
      final first = messages.first;
      final time = first.sendTime > 0 ? formatTimestamp(first.sendTime) : '';
      preview =
          '$time ${first.sendUserNickname ?? ''}：'
          '${messageContentPreview(first)}';
    }
    return GestureDetector(
      onTap: () {
        // 快照为空不跳转
        if (messages == null || messages.isEmpty) {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ChatRecordDetailPage(messages: messages),
          ),
        );
      },
      child: _buildMsgLayout(
        child: Container(
          key: _contentKey,
          width: 230.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _isSelf
                ? const Color.fromRGBO(20, 134, 237, 1)
                : Colors.white,
            borderRadius: .circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  Text(
                    '聊天记录',
                    style: TextStyle(
                      color: _isSelf ? Colors.white : Colors.black,
                      fontSize: 16.sp,
                      fontWeight: .bold,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: .symmetric(horizontal: 6.w, vertical: 2.w),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: .circular(4.r),
                    ),
                    child: Text(
                      '[$count条聊天记录]',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _isSelf ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.w),
              Divider(
                height: 1,
                color: _isSelf
                    ? const Color.fromRGBO(255, 255, 255, 77)
                    : const Color.fromRGBO(220, 220, 220, 1),
              ),
              SizedBox(height: 8.w),
              Text(
                preview,
                maxLines: 2,
                overflow: .ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _isSelf
                      ? const Color.fromRGBO(255, 255, 255, 217)
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        color: _isSelf
            ? const Color.fromRGBO(20, 134, 237, 1)
            : Colors.white,
      ),
    );
  }

  // 构建菜单项
  Widget _buildContextMenuItems(List<ContextMenuItem> items) {
    return Row(
      children: List.generate(
        items.length,
        (index) => GestureDetector(
          onTap: items[index].onTap,
          child: Padding(
            padding: .symmetric(horizontal: 5.w, vertical: 12.w),
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
      ),
    );
  }

  // 构建上下文菜单
  Widget _buildContextMenu(List<ContextMenuItem> items, bool topVisible) {
    return CustomPaint(
      painter: ContextMenuArrowPainter(topVisible: topVisible),
      child: Container(
        padding: .symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(75, 75, 75, 1),
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

  // 撤回消息
  void _recallMessage() {
    // 隐藏上下文菜单
    _hideContextMenu();
    // 弹出确认框
    showPromptDialog(
      context,
      '是否要撤回该消息?',
      showCancel: true,
      onConfirm: () async {
        await recallMessageApi(widget.message.messageId);
        ToastUtils.showGlobalToast(
          msg: '已撤回',
          duration: Duration(milliseconds: 1500),
        );
        setState(() {
          final message = widget.message;
          message.status = MessageStatusEnum.recalled.status;
          // 更新会话lastMessage
          sessionStore.updateLastMessage(
            message.sessionId,
            '已撤回一条消息',
            DateTime.now().millisecondsSinceEpoch,
          );
        });
      },
    );
  }

  // 显示上下文菜单
  void _showContextMenu() {
    final message = widget.message;
    // 详情页/多选模式不弹菜单
    if (!widget.showMenu || widget.multiSelectMode) {
      return;
    }
    // 系统通知不弹菜单
    if (message.messageType == MessageTypeEnum.systemNotice.type) {
      return;
    }
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
      if (message.messageType == MessageTypeEnum.text.type)
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
      // 只有文本，媒体文件，个人卡片，语音，聊天记录可以转发
      if ([
        MessageTypeEnum.text.type,
        MessageTypeEnum.file.type,
        MessageTypeEnum.personCard.type,
        MessageTypeEnum.voice.type,
        MessageTypeEnum.chatRecord.type,
      ].contains(message.messageType))
        ContextMenuItem(
          icon: Icons.share,
          text: '转发',
          onTap: () {
            // 隐藏上下文菜单
            _hideContextMenu();
            // 跳转到选择联系人页面
            Navigator.push(
              context,
              RouteUtils.slideUp(
                (ctx) => ContactSelectPage(
                  onSelect: (contact) async {
                    final res = await showPromptDialog(
                      context,
                      '是否确定向${contact.contactName}转发此消息?',
                      showCancel: true,
                    );
                    // 用户取消转发
                    if (res == null || !res) {
                      return false;
                    }
                    // 用户确认转发
                    widget.onShareMessage(message, contact);
                    return true;
                  },
                ),
                settings: RouteSettings(arguments: {'searchAll': true}),
              ),
            );
          },
        ),
      // 多选(合并转发)
      if (widget.onMultiSelect != null)
        ContextMenuItem(
          icon: Icons.checklist_rounded,
          text: '多选',
          onTap: () {
            _hideContextMenu();
            widget.onMultiSelect?.call();
          },
        ),
      // 发送后五分钟之内才可以撤回(通话消息不可撤回，与后端白名单一致)
      if (_isSelf &&
          DateTime.now().millisecondsSinceEpoch - message.sendTime <
              GlobalConstants.recallLimit &&
          message.messageType != MessageTypeEnum.videoCall.type &&
          message.messageType != MessageTypeEnum.voiceCall.type)
        ContextMenuItem(icon: Icons.delete, text: '撤回', onTap: _recallMessage),
    ];
    // 上下文菜单水平偏移量: 消息内容宽度的一半-菜单宽度的一半
    final menuWidth = 30.w + 28.sp * items.length + 15.w * (items.length - 1);
    final menuHeight = 32.sp + 35.w;
    final leftOffset = (width / 2) - (menuWidth / 2);
    // 钳制到屏幕范围内, 防止4项菜单在屏幕边缘溢出
    // 菜单宽度超过屏幕时直接贴左, 否则钳制在屏幕范围内
    final menuLeft = menuWidth > 1.sw - 10.w
        ? 5.w
        : (offset.dx + leftOffset).clamp(5.w, 1.sw - menuWidth - 5.w);
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
              left: menuLeft,
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

  // 构建通话消息（语音/视频共用，根据data中的status展示不同状态）
  Widget _buildCallMsg(MessageTypeEnum type) {
    final icon = type == MessageTypeEnum.voiceCall
        ? MyIcon.voice
        : MyIcon.video;
    String content;
    final msgData = widget.message.data;
    if (msgData == null) {
      // data为空（通话尚未结束），显示默认文案
      content = type.messageContent;
    } else {
      try {
        final data = jsonDecode(msgData);
        final status = data['status'];
        final duration = data['duration'];
        if (status == CallStatusEnum.reject.status) {
          // 拒绝接听
          content = '未接听';
        } else if (status == CallStatusEnum.abnormal.status) {
          // 异常挂断
          content = '通话中断';
        } else if (duration != null) {
          // 正常接听（兼容旧数据：无status但有duration）
          content = '通话时长 ${formatDuration(duration)}';
        } else {
          content = type.messageContent;
        }
      } catch (_) {
        // 数据损坏时显示默认文案
        content = type.messageContent;
      }
    }
    return _buildMsgLayout(
      child: GestureDetector(
        onTap: () {
          widget.onVideoOrVoiceCall(type);
        },
        child: Container(
          key: _contentKey,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.w),
          decoration: BoxDecoration(
            color: _isSelf
                ? const Color.fromRGBO(20, 134, 237, 1)
                : Colors.white,
            borderRadius: .circular(8.r),
          ),
          child: Row(
            mainAxisSize: .min,
            spacing: 5.w,
            children: [
              Text(
                content,
                style: TextStyle(color: _isSelf ? Colors.white : Colors.black),
              ),
              Icon(
                icon,
                size: 18.sp,
                color: _isSelf ? Colors.white : Colors.black,
              ),
            ],
          ),
        ),
      ),
      color: _isSelf ? const Color.fromRGBO(20, 134, 237, 1) : Colors.white,
    );
  }

  // 构建语音通话消息
  Widget _buildVoiceCall() {
    return _buildCallMsg(MessageTypeEnum.voiceCall);
  }

  // 构建视频通话消息
  Widget _buildVideoCall() {
    return _buildCallMsg(MessageTypeEnum.videoCall);
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
    } else if (messageType == MessageTypeEnum.personCard.type) {
      // 个人卡片
      return _buildPersonCard();
    } else if (messageType == MessageTypeEnum.videoCall.type) {
      // 视频通话
      return _buildVideoCall();
    } else if (messageType == MessageTypeEnum.voiceCall.type) {
      // 语音通话
      return _buildVoiceCall();
    } else if (messageType == MessageTypeEnum.voice.type) {
      // 语音消息
      return _buildVoiceMsg();
    } else if (messageType == MessageTypeEnum.chatRecord.type) {
      // 聊天记录
      return _buildChatRecordMsg();
    }
    return _buildTextMsg('未知消息类型');
  }

  // 构建消息内容
  Widget _buildMsgContent() {
    // 多选模式: 点击气泡勾选/取消(IgnorePointer屏蔽内部手势, opaque保证外层命中)
    if (widget.multiSelectMode) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelectTap,
        child: IgnorePointer(child: _getContent()),
      );
    }
    return GestureDetector(
      onTap: _hideContextMenu,
      onLongPress: _showContextMenu,
      child: _getContent(),
    );
  }

  // 构建用户头像
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RoutePath.contactInfo,
          arguments: {'contactId': widget.message.sendUserId},
        );
      },
      child: ContactAvatar(contactId: widget.message.sendUserId ?? '-1'),
    );
  }

  // 构建多选勾选框
  Widget _buildSelectCheckbox() {
    final selectable = widget.onSelectTap != null;
    return GestureDetector(
      onTap: selectable ? widget.onSelectTap : null,
      child: Container(
        width: 20.w,
        height: 20.w,
        margin: EdgeInsets.only(top: 12.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.selected
              ? const Color.fromRGBO(20, 134, 237, 1)
              : Colors.white,
          border: Border.all(
            color: widget.selected
                ? const Color.fromRGBO(20, 134, 237, 1)
                : const Color.fromRGBO(170, 170, 170, 1),
            width: 1.5,
          ),
        ),
        child: widget.selected
            ? Icon(Icons.check, size: 14.w, color: Colors.white)
            : null,
      ),
    );
  }

  // 构建消息
  Widget _buildMsg() {
    // 多选模式勾选框(只有可勾选的消息才显示)
    final showCheckbox = widget.multiSelectMode && widget.onSelectTap != null;
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
              // 头像(多选模式屏蔽点击)
              IgnorePointer(
                ignoring: widget.multiSelectMode,
                child: _buildAvatar(),
              ),
              // 多选勾选框(最外侧)
              if (showCheckbox) _buildSelectCheckbox(),
            ]
          : [
              // 多选勾选框(最外侧)
              if (showCheckbox) _buildSelectCheckbox(),
              // 头像(多选模式屏蔽点击)
              IgnorePointer(
                ignoring: widget.multiSelectMode,
                child: _buildAvatar(),
              ),
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

  // 构建主体内容
  Widget _buildMain() {
    final status = widget.message.status;
    if (status == MessageStatusEnum.sent.status) {
      return widget.message.messageType != MessageTypeEnum.systemNotice.type
          ? _buildMsg()
          : _buildSystemNotice(widget.message.messageContent);
    } else if (status == MessageStatusEnum.recalled.status) {
      return _buildSystemNotice(
        _isSelf ? '已撤回一条消息' : '${widget.message.sendUserNickname}已撤回一条消息',
      );
    }
    return _buildSystemNotice('发送中');
  }

  // 是否是当前用户发送的消息
  bool get _isSelf =>
      _userController.userInfo.value?.userId == widget.message.sendUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 10.w, right: 10.w, bottom: 10.w),
      child: _buildMain(),
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
      ..color = const Color.fromRGBO(75, 75, 75, 1)
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

// 语音播放动画图标(三条相位错开的跳动音波)
class _VoicePlayingIcon extends StatefulWidget {
  final Color color;

  const _VoicePlayingIcon({required this.color});

  @override
  State<_VoicePlayingIcon> createState() => _VoicePlayingIconState();
}

class _VoicePlayingIconState extends State<_VoicePlayingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (index) {
            // 相位错开的三条音波
            final t = (sin(_controller.value * 2 * pi + index * 2) + 1) / 2;
            final height = 5.w + t * 9.w;
            return Container(
              width: 3.w,
              height: height,
              margin: EdgeInsets.only(right: 3.w),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        );
      },
    );
  }
}
