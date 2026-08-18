import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:zchat/api/moments.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/moments.dart';
import 'package:zchat/stores/message.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/moments_background.dart';
import 'package:zchat/widgets/moments_post_card.dart';
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

  // 是否已上传过朋友圈背景
  bool _hasBackground = false;
  // 背景版本号（每次修改+1，用于强制刷新缓存）
  int _bgVersion = 0;

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

  // 构建顶部区域
  Widget _buildTop() {
    return Stack(
      clipBehavior: .none,
      children: [
        // 背景区域：未上传时点击更换，已上传时点击预览、长按更换
        GestureDetector(
          onTap: _hasBackground ? _previewBackground : _showBackgroundSheet,
          onLongPress: _showBackgroundSheet,
          child: SizedBox(
            width: double.infinity,
            height: _topHeight,
            child: MomentsBackground(
              userId: _userController.userInfo.value?.userId ?? '-1',
              hintText: '轻触更换背景',
              version: _bgVersion,
              heroTag: 'moments_bg_${_userController.userInfo.value?.userId}',
              onStateChanged: (has) {
                if (has != _hasBackground) {
                  setState(() => _hasBackground = has);
                }
              },
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

  // 预览背景图片
  void _previewBackground() {
    final userId = _userController.userInfo.value?.userId ?? '-1';
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: PhotoView(
                imageProvider: NetworkImage(
                  '${GlobalConstants.momentsBackgroundUrl}/$userId.jpg?v=$_bgVersion',
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'moments_bg_$userId',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 修改朋友圈背景
  void _updateBackground(ImageSource source) async {
    // 选择图片
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) {
      return;
    }
    // 校验文件大小
    final fileSize = await image.length();
    if (fileSize > GlobalConstants.imageMaxSize) {
      return ToastUtils.showGlobalToast(
        msg: '背景图片不能大于${GlobalConstants.imageMaxMB}MB',
      );
    }
    // 封装multipart并上传
    final file = await MultipartFile.fromFile(image.path);
    await updateMomentsBackgroundApi(file);
    // 版本号+1，触发背景图片重新加载
    setState(() => _bgVersion++);
    // 关闭sheet
    Navigator.pop(context);
  }

  // 显示修改背景sheet
  void _showBackgroundSheet() {
    showMyBottomSheet(context, [
      SheetItem('从相册中选择图片', () {
        _updateBackground(ImageSource.gallery);
      }),
      SheetItem('拍照', () {
        _updateBackground(ImageSource.camera);
      }),
    ]);
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

  // 构建悬浮按钮（回到顶部 + 我的动态）
  Widget _buildFloatButtons() {
    return Positioned(
      right: 15.w,
      bottom: 40.w,
      child: Column(
        spacing: 12.w,
        children: [
          // 回到顶部按钮（顶部不可见时显示）
          if (!_isTopVisible)
            GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: .circle,
                  color: Colors.black.withOpacity(0.4),
                ),
                alignment: .center,
                child: Icon(
                  Icons.keyboard_double_arrow_up,
                  color: Colors.white,
                  size: 22.w,
                ),
              ),
            ),
          // 我的动态按钮（跳转到当前用户的动态页面）
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                RoutePath.momentsUser,
                arguments: {
                  'userId': _userController.userInfo.value?.userId ?? '',
                  'nickname': _userController.userInfo.value?.nickname ?? '',
                },
              );
            },
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: .circle,
                color: Colors.black.withOpacity(0.4),
              ),
              alignment: .center,
              child: Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 22.w,
              ),
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
      padding: EdgeInsets.only(top: 50.w),
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
            return MomentsPostCard(post: _posts[postIndex]);
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
        child: Stack(
          children: [_buildMain(), _buildPageHeader(), _buildFloatButtons()],
        ),
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
