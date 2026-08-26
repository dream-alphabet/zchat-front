import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:zchat/api/moments.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/moments.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 朋友圈动态卡片（首页和个人动态页共用）
class MomentsPostCard extends StatefulWidget {
  final MomentsPostItem post;

  const MomentsPostCard({super.key, required this.post});

  @override
  State<MomentsPostCard> createState() => _MomentsPostCardState();
}

class _MomentsPostCardState extends State<MomentsPostCard> {
  // 用户store
  final _userController = Get.find<UserController>();
  // 联系人store
  final _userContactController = Get.find<UserContactController>();
  // 点赞列表是否展开
  bool _likesExpanded = false;
  // 评论列表是否展开
  bool _commentsExpanded = false;
  // SelectableText焦点控制器
  final _textFocusNode = FocusNode();
  // 上下文菜单悬浮覆盖层
  OverlayEntry? _contextMenuOverlay;

  MomentsPostItem get post => widget.post;

  // 格式化时间
  String _formatTime(String timeStr) {
    try {
      final time = DateTime.parse(timeStr);
      final diff = DateTime.now().difference(time);
      if (diff.inSeconds < 60) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${time.month}-${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  // 点赞/取消点赞
  Future<void> _toggleLike() async {
    await toggleLikeApi(post.postId);
    setState(() {
      post.liked = !post.liked;
      if (post.liked) {
        post.likeList.add(
          MomentsLikeItem(
            userId: _userController.userInfo.value?.userId ?? '',
            nickname: _userController.userInfo.value?.nickname ?? '',
          ),
        );
      } else {
        post.likeList.removeWhere(
          (like) => like.userId == _userController.userInfo.value?.userId,
        );
      }
    });
  }

  // 显示评论输入弹窗
  void _showCommentInput({
    int? parentId,
    String? replyToUserId,
    String? replyToNickname,
  }) {
    final controller = TextEditingController();
    final hintText = replyToNickname != null ? '回复 $replyToNickname' : '评论';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16.w,
              right: 16.w,
              top: 16.w,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.w,
                    ),
                  ),
                ),
                SizedBox(height: 12.w),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final content = controller.text.trim();
                      if (content.isEmpty) {
                        ToastUtils.showGlobalToast(msg: '评论内容不能为空');
                        return;
                      }
                      final comment = await addCommentApi(
                        postId: post.postId,
                        content: content,
                        parentId: parentId,
                        replyToUserId: replyToUserId,
                      );
                      setState(() {
                        post.commentList.add(comment);
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(20, 134, 237, 1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.w),
                    ),
                    child: Text('发送', style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
                SizedBox(height: 16.w),
              ],
            ),
          ),
        );
      },
    );
  }

  // 删除评论
  Future<void> _deleteComment(MomentsCommentItem comment) async {
    await deleteCommentApi(comment.id);
    setState(() {
      post.commentList.removeWhere((c) => c.id == comment.id);
    });
  }

  // 显示删除评论确认弹窗
  void _showDeleteCommentDialog(MomentsCommentItem comment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除评论'),
        content: Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteComment(comment);
            },
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 显示操作菜单（点赞/评论）
  void _showActionMenu(Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'like',
        child: Row(
          mainAxisAlignment: .center,
          spacing: 10.w,
          children: [
            Icon(
              post.liked ? Icons.favorite : Icons.favorite_border,
              color: post.liked ? Colors.red : Colors.white,
              size: 20.w,
            ),
            Text(
              post.liked ? '取消点赞' : '点赞',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'comment',
        child: Row(
          mainAxisAlignment: .center,
          spacing: 10.w,
          children: [
            Icon(Icons.comment_outlined, size: 20.w, color: Colors.white),
            Text('评论', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ];
    showMenu<String>(
      context: context,
      color: Color.fromRGBO(87, 87, 87, 1),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: items,
    ).then((value) {
      if (value == 'like') {
        _toggleLike();
      } else if (value == 'comment') {
        _showCommentInput();
      }
    });
  }

  // 生成唯一Hero tag
  String _heroTag(int postId, int sortOrder) => 'moments_${postId}_$sortOrder';

  // 预览图片
  void _previewImages(int initialIndex) {
    final mediaList = post.mediaList;
    final controller = PageController(initialPage: initialIndex);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: PhotoViewGallery.builder(
              pageController: controller,
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                final media = mediaList[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(media.fileUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: _heroTag(post.postId, media.sortOrder),
                  ),
                );
              },
              itemCount: mediaList.length,
            ),
          ),
        ),
      ),
    ).then((_) => controller.dispose());
  }

  // 构建图片网格
  Widget _buildImageGrid() {
    final mediaList = post.mediaList;
    if (mediaList.isEmpty) return const SizedBox.shrink();
    final count = mediaList.length;
    int crossAxisCount;
    double imgSize;
    if (count == 1) {
      crossAxisCount = 1;
      imgSize = 180.w;
    } else if (count == 2 || count == 4) {
      crossAxisCount = 2;
      imgSize = 120.w;
    } else {
      crossAxisCount = 3;
      imgSize = 80.w;
    }
    // 限制解码尺寸(显示尺寸对应的物理像素), 避免朋友圈图片全分辨率解码
    final cacheSize = (imgSize * MediaQuery.devicePixelRatioOf(context)).round();

    return SizedBox(
      width: crossAxisCount == 1
          ? imgSize
          : (imgSize + 4.w) * crossAxisCount - 4.w,
      child: Wrap(
        spacing: 4.w,
        runSpacing: 4.w,
        children: List.generate(mediaList.length, (index) {
          final media = mediaList[index];
          return GestureDetector(
            onTap: () => _previewImages(index),
            child: Hero(
              tag: _heroTag(post.postId, media.sortOrder),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Image.network(
                  media.fileUrl,
                  width: imgSize,
                  height: imgSize,
                  fit: BoxFit.cover,
                  cacheWidth: cacheSize,
                  cacheHeight: cacheSize,
                  errorBuilder: (_, _, _) => Container(
                    width: imgSize,
                    height: imgSize,
                    color: Color.fromRGBO(237, 237, 237, 1),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 构建点赞列表
  Widget _buildLikeList() {
    final likeList = post.likeList;
    if (likeList.isEmpty) return const SizedBox.shrink();
    final displayList = (likeList.length > 5 && !_likesExpanded)
        ? likeList.sublist(0, 5)
        : likeList;
    final hasMore = likeList.length > 5;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: Color.fromRGBO(245, 245, 245, 1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Wrap(
        spacing: 4.w,
        runSpacing: 4.w,
        crossAxisAlignment: .center,
        children: [
          Icon(Icons.favorite, size: 16.w, color: Colors.red),
          ...displayList.map((like) {
            final contact = _userContactController.getUserContact(like.userId);
            final name = contact?.contactName ?? like.nickname;
            return Text(
              name,
              style: TextStyle(
                fontSize: 14.sp,
                color: Color.fromRGBO(87, 107, 149, 1),
              ),
            );
          }),
          if (hasMore)
            GestureDetector(
              onTap: () => setState(() {
                _likesExpanded = !_likesExpanded;
              }),
              child: Text(
                _likesExpanded ? '收起' : '...等${likeList.length}人',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color.fromRGBO(167, 167, 167, 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 构建评论列表
  Widget _buildCommentList() {
    final commentList = post.commentList;
    if (commentList.isEmpty) return const SizedBox.shrink();
    final isMyPost = post.userId == _userController.userInfo.value?.userId;
    final displayList = (commentList.length > 3 && !_commentsExpanded)
        ? commentList.sublist(0, 3)
        : commentList;
    final hasMore = commentList.length > 3;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: Color.fromRGBO(245, 245, 245, 1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayList.map((comment) {
            final contact = _userContactController.getUserContact(
              comment.userId,
            );
            final commenterName = contact?.contactName ?? comment.nickname;
            return GestureDetector(
              onLongPress: isMyPost
                  ? () => _showDeleteCommentDialog(comment)
                  : null,
              onTap: () => _showCommentInput(
                parentId: comment.id,
                replyToUserId: comment.userId,
                replyToNickname: commenterName,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.w),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: commenterName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color.fromRGBO(87, 107, 149, 1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (comment.replyToNickname != null &&
                          comment.replyToUserId != null) ...[
                        TextSpan(
                          text: ' 回复 ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text:
                              _userContactController
                                  .getUserContact(comment.replyToUserId!)
                                  ?.contactName ??
                              comment.replyToNickname!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Color.fromRGBO(87, 107, 149, 1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      TextSpan(
                        text: ': ${comment.content}',
                        style: TextStyle(fontSize: 14.sp, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (hasMore)
            GestureDetector(
              onTap: () => setState(() {
                _commentsExpanded = !_commentsExpanded;
              }),
              child: Padding(
                padding: EdgeInsets.only(top: 4.w),
                child: Text(
                  _commentsExpanded ? '收起' : '展开全部${commentList.length}条评论',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Color.fromRGBO(167, 167, 167, 1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 跳转到发布者的联系人信息页面
  void _goToContactInfo() {
    Navigator.pushNamed(
      context,
      RoutePath.contactInfo,
      arguments: {'contactId': post.userId},
    );
  }

  // 关闭上下文菜单并清除选区
  void _hideContextMenu() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
    _textFocusNode.unfocus();
  }

  // 显示文本上下文菜单（长按选中后弹出）
  void _showContextMenu() {
    // 防止重复弹出
    if (_contextMenuOverlay != null) {
      return;
    }

    _contextMenuOverlay = OverlayEntry(
      builder: (context) {
        // 全屏透明点击区，点击外部关闭菜单并清除选区
        return GestureDetector(
          onTap: _hideContextMenu,
          behavior: .opaque,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
        );
      },
    );
    // 插入覆盖层
    Overlay.of(context).insert(_contextMenuOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    String contactName = post.nickname;
    final contact = _userContactController.getUserContact(post.userId);
    if (contact != null) {
      contactName = contact.contactName;
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(237, 237, 237, 1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像（点击跳转联系人信息）
          GestureDetector(
            onTap: _goToContactInfo,
            child: ContactAvatar(contactId: post.userId, size: 40),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6.w,
              children: [
                // 昵称（点击跳转联系人信息）
                GestureDetector(
                  onTap: _goToContactInfo,
                  child: Text(
                    contactName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(87, 107, 149, 1),
                    ),
                  ),
                ),
                if (post.content != null && post.content!.isNotEmpty)
                  SelectableText(
                    post.content!,
                    focusNode: _textFocusNode,
                    onSelectionChanged: (selection, cause) {
                      // 没有选中文本就强行关闭overlay
                      if (selection.start == selection.end) {
                        _hideContextMenu();
                      }
                      // 长按选中时弹出上下文菜单
                      if (cause == SelectionChangedCause.longPress) {
                        _showContextMenu();
                      }
                    },
                    style: TextStyle(fontSize: 16.sp, color: Colors.black),
                  ),
                if (post.mediaList.isNotEmpty) _buildImageGrid(),
                Row(
                  spacing: 15.w,
                  children: [
                    Text(
                      _formatTime(post.createTime),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Color.fromRGBO(167, 167, 167, 1),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTapDown: (details) =>
                          _showActionMenu(details.globalPosition),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.w,
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(245, 245, 245, 1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.more_horiz,
                          size: 18.sp,
                          color: Color.fromRGBO(167, 167, 167, 1),
                        ),
                      ),
                    ),
                  ],
                ),
                if (post.likeList.isNotEmpty) _buildLikeList(),
                if (post.commentList.isNotEmpty) _buildCommentList(),
              ],
            ),
          ),
        ],
      ),
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
