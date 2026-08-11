import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:zchat/api/moments.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/moments.dart';
import 'package:zchat/stores/contact.dart';
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
  void _previewImages(List<MomentsMediaItem> mediaList, int initialIndex, int postId) {
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
                  errorBuilder: (_, __, ___) => Container(
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
                if (post.mediaList.isNotEmpty) _buildImageGrid(post.mediaList, post.postId),
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
                      onTap: () {
                        // TODO: 点击...展开操作菜单
                      },
                      child: Icon(
                        Icons.more_horiz,
                        size: 18.sp,
                        color: Color.fromRGBO(167, 167, 167, 1),
                      ),
                    ),
                  ],
                ),
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
          statusBarColor: Colors.white,
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
