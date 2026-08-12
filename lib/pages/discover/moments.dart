import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:zchat/api/moments.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/moments.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/stores/message.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/page_header.dart';

// 朋友圈
class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  // 用户store
  final _userController = Get.find<UserController>();
  // 消息store
  final _messageController = Get.find<MessageController>();

  // 滚动控制器
  final _scrollController = ScrollController();

  // 顶部是否可见
  bool _isTopVisible = true;

  // 顶部区域高度
  final _topHeight = 300.w;

  // 动态列表
  final List<MomentsPostItem> _posts = [];

  // 联系人store
  final _userContactController = Get.find<UserContactController>();

  // 是否正在刷新
  bool _isRefreshing = false;

  // 展开状态的点赞列表postId集合
  final Set<int> _expandedLikes = {};
  // 展开状态的评论列表postId集合
  final Set<int> _expandedComments = {};
  // 是否正在加载更多
  bool _isLoadingMore = false;
  // 是否还有更多
  bool _hasMore = true;
  // 当前页码
  int _page = 1;

  // 顶部状态栏和header的图标颜色
  Color get _topIconColor => _isTopVisible ? Colors.white : Colors.black;

  // 顶部状态栏背景颜色
  Color get _topColor => _isTopVisible
      ? Color.fromRGBO(87, 87, 87, 1)
      : Color.fromRGBO(227, 227, 227, 1);

  @override
  void initState() {
    super.initState();
    // 延迟到帧结束再修改
    // 不能在build之前清空因为Obx在build之前重构会有问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 清空朋友圈未读数量
      _messageController.clearUnreadCount(UnreadType.share);
    });
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  // 加载数据（刷新）
  Future<void> _loadData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final res = await getTimelineApi(page: 1);
      setState(() {
        _posts.clear();
        _posts.addAll(List<MomentsPostItem>.from(res.list));
        _page = 1;
        _hasMore = _page < res.pages;
      });
    } catch (_) {
      // request.dart handles toast
    }
    setState(() => _isRefreshing = false);
  }

  // 加载更多
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final res = await getTimelineApi(page: _page + 1);
      setState(() {
        _posts.addAll(List<MomentsPostItem>.from(res.list));
        _page++;
        _hasMore = _page < res.pages;
      });
    } catch (_) {
      // request.dart handles toast
    }
    setState(() => _isLoadingMore = false);
  }

  // 滚动事件：监听触底 + 顶部可见性
  void _onScroll() {
    // 顶部可见性
    final bool visible = _scrollController.offset < _topHeight;
    if (visible != _isTopVisible) {
      setState(() {
        _isTopVisible = visible;
      });
    }
    // 触底加载更多
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100.w) {
      _loadMore();
    }
  }

  // 格式化时间（简化为刚刚/分钟前/小时前/天前）
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
  Future<void> _toggleLike(MomentsPostItem post) async {
    try {
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
    } catch (_) {
      // request.dart handles toast
    }
  }

  // 显示评论输入弹窗
  void _showCommentInput(
    MomentsPostItem post, {
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
  Future<void> _deleteComment(
    MomentsPostItem post,
    MomentsCommentItem comment,
  ) async {
    await deleteCommentApi(comment.id);
    setState(() {
      post.commentList.removeWhere((c) => c.id == comment.id);
    });
  }

  // 显示操作菜单（点赞/评论）
  void _showActionMenu(MomentsPostItem post, Offset position) {
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
        _toggleLike(post);
      } else if (value == 'comment') {
        _showCommentInput(post);
      }
    });
  }

  // 构建点赞列表
  Widget _buildLikeList(List<MomentsLikeItem> likeList, int postId) {
    if (likeList.isEmpty) return const SizedBox.shrink();
    final isExpanded = _expandedLikes.contains(postId);
    // 超过5个且未展开时只显示前5个
    final displayList = (likeList.length > 5 && !isExpanded)
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
                isExpanded
                    ? _expandedLikes.remove(postId)
                    : _expandedLikes.add(postId);
              }),
              child: Text(
                isExpanded ? '收起' : '...等${likeList.length}人',
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
  Widget _buildCommentList(MomentsPostItem post) {
    if (post.commentList.isEmpty) return const SizedBox.shrink();
    final isMyPost = post.userId == _userController.userInfo.value?.userId;
    final isExpanded = _expandedComments.contains(post.postId);
    // 超过3条且未展开时只显示前3条
    final displayList = (post.commentList.length > 3 && !isExpanded)
        ? post.commentList.sublist(0, 3)
        : post.commentList;
    final hasMore = post.commentList.length > 3;

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
                  ? () => _showDeleteCommentDialog(post, comment)
                  : null,
              onTap: () => _showCommentInput(
                post,
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
                isExpanded
                    ? _expandedComments.remove(post.postId)
                    : _expandedComments.add(post.postId);
              }),
              child: Padding(
                padding: EdgeInsets.only(top: 4.w),
                child: Text(
                  isExpanded ? '收起' : '展开全部${post.commentList.length}条评论',
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

  // 显示删除评论确认弹窗
  void _showDeleteCommentDialog(
    MomentsPostItem post,
    MomentsCommentItem comment,
  ) {
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
              _deleteComment(post, comment);
            },
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 构建顶部区域
  Widget _buildTop() {
    return Stack(
      clipBehavior: .none,
      children: [
        Container(
          width: double.infinity,
          height: _topHeight,
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
          alignment: .center,
          child: Text(
            '轻触更换封面',
            style: TextStyle(
              fontSize: 14.sp,
              color: Color.fromRGBO(134, 134, 134, 1),
            ),
          ),
        ),
        Positioned(
          right: 80.w,
          bottom: 2.w,
          child: Text(
            _userController.userInfo.value?.nickname ?? '',
            style: TextStyle(fontSize: 20.sp, color: Colors.white),
          ),
        ),
        Positioned(
          right: 10.w,
          bottom: -20.w,
          child: ContactAvatar(
            contactId: _userController.userInfo.value?.userId ?? '-1',
            size: 60,
            shape: .rectangle,
          ),
        ),
      ],
    );
  }

  // 构建页面头部
  Widget _buildPageHeader() {
    return PageHeader(
      title: _isTopVisible ? '' : '朋友圈',
      showLeftBackIcon: true,
      showRightIcon: true,
      backgroundColor: _isTopVisible
          ? Colors.transparent
          : Color.fromRGBO(227, 227, 227, 1),
      showBorder: false,
      iconColor: _topIconColor,
      rightIconList: [
        GestureDetector(
          onTap: () async {
            await Navigator.pushNamed(context, RoutePath.momentsPublish);
            _loadData();
          },
          child: Icon(
            Icons.camera_alt_outlined,
            size: 22.sp,
            color: _topIconColor,
          ),
        ),
      ],
    );
  }

  // 预览图片
  // 生成唯一Hero tag
  String _heroTag(int postId, int sortOrder) => 'moments_${postId}_$sortOrder';

  // 预览图片
  void _previewImages(
    List<MomentsMediaItem> mediaList,
    int initialIndex,
    int postId,
  ) {
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
                    tag: _heroTag(postId, media.sortOrder),
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
  Widget _buildImageGrid(List<MomentsMediaItem> mediaList, int postId) {
    if (mediaList.isEmpty) return const SizedBox.shrink();
    final count = mediaList.length;
    // 计算列数
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
            onTap: () => _previewImages(mediaList, index, postId),
            child: Hero(
              tag: _heroTag(postId, media.sortOrder),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Image.network(
                  media.fileUrl,
                  width: imgSize,
                  height: imgSize,
                  fit: BoxFit.cover,
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

  // 构建单条动态卡片
  Widget _buildPostItem(MomentsPostItem post) {
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
          ContactAvatar(contactId: post.userId, size: 40),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6.w,
              children: [
                Text(
                  contactName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(87, 107, 149, 1),
                  ),
                ),
                if (post.content != null && post.content!.isNotEmpty)
                  Text(
                    post.content!,
                    style: TextStyle(fontSize: 16.sp, color: Colors.black),
                  ),
                if (post.mediaList.isNotEmpty)
                  _buildImageGrid(post.mediaList, post.postId),
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
                          _showActionMenu(post, details.globalPosition),
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
                // 点赞列表
                if (post.likeList.isNotEmpty)
                  _buildLikeList(post.likeList, post.postId),
                // 评论列表
                if (post.commentList.isNotEmpty) _buildCommentList(post),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建底部加载指示器
  Widget _buildLoadMoreIndicator() {
    if (_posts.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.w),
      alignment: .center,
      child: _hasMore
          ? SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color.fromRGBO(167, 167, 167, 1),
              ),
            )
          : Text(
              '没有更多了',
              style: TextStyle(
                fontSize: 12.sp,
                color: Color.fromRGBO(167, 167, 167, 1),
              ),
            ),
    );
  }

  // 构建空状态（内嵌在 ListView 中，避免阻挡下拉刷新）
  Widget _buildEmptyContent() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 200.w),
      child: Column(
        spacing: 10.w,
        children: [
          Icon(Icons.photo_camera, size: 60.w, color: Colors.grey),
          Text(
            '还没有动态，去发布一条吧',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 主要内容
  Widget _buildMain() {
    // 空且非刷新中，多加一个空状态位
    final hasEmpty = _posts.isEmpty && !_isRefreshing;
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Color.fromRGBO(20, 134, 237, 1),
      child: ListView.builder(
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: _posts.length + 2, // top + posts + (loadMore|empty)
        itemBuilder: (ctx, index) {
          if (index == 0) {
            return _buildTop();
          }
          final postIndex = index - 1;
          if (postIndex < _posts.length) {
            return _buildPostItem(_posts[postIndex]);
          }
          if (postIndex == _posts.length && !hasEmpty) {
            return _buildLoadMoreIndicator();
          }
          return _buildEmptyContent();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: _topColor,
        bottomOpacity: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: _topColor,
          statusBarBrightness: _isTopVisible
              ? Brightness.dark
              : Brightness.light,
          statusBarIconBrightness: _isTopVisible
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(children: [_buildMain(), _buildPageHeader()]),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
