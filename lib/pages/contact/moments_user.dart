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
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/modal.dart';
import 'package:zchat/widgets/moments_background.dart';
import 'package:zchat/widgets/moments_post_card.dart';
import 'package:zchat/widgets/page_header.dart';

// 用户朋友圈页面（查看自己或好友的动态）
class MomentsUserPage extends StatefulWidget {
  const MomentsUserPage({super.key});

  @override
  State<MomentsUserPage> createState() => _MomentsUserPageState();
}

class _MomentsUserPageState extends State<MomentsUserPage> {
  // 用户store
  final _userController = Get.find<UserController>();

  // 目标用户id
  String _userId = '';
  // 目标用户昵称
  String _nickname = '';

  // 滚动控制器
  final _scrollController = ScrollController();

  // 顶部是否可见
  bool _isTopVisible = true;

  // 顶部状态栏背景颜色
  Color get _topColor => _isTopVisible
      ? Color.fromRGBO(87, 87, 87, 1)
      : Color.fromRGBO(227, 227, 227, 1);

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

  // 是否是查看自己
  bool get _isSelf => _userId == _userController.userInfo.value?.userId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _userId = params['userId'];
        _nickname = params['nickname'] ?? '';
        setState(() {});
        _loadData();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  // 加载数据（刷新）
  Future<void> _loadData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final res = await getUserTimelineApi(userId: _userId, page: 1);
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
      final res = await getUserTimelineApi(userId: _userId, page: _page + 1);
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

  // 滚动事件：触底加载更多 + 顶部可见性
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

  // 构建顶部背景区域（与朋友圈首页一致）
  Widget _buildTop() {
    return Stack(
      clipBehavior: .none,
      children: [
        // 背景区域：
        // 查看自己：未上传时点击更换，已上传时点击预览、长按更换
        // 查看好友：已上传时点击预览，不能修改
        GestureDetector(
          onTap: _hasBackground
              ? _previewBackground
              : (_isSelf ? _showBackgroundSheet : null),
          onLongPress: _isSelf ? _showBackgroundSheet : null,
          child: SizedBox(
            width: double.infinity,
            height: _topHeight,
            child: MomentsBackground(
              userId: _userId,
              hintText: _isSelf ? '轻触更换背景' : null,
              version: _bgVersion,
              heroTag: 'moments_bg_$_userId',
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
            _nickname,
            style: TextStyle(fontSize: 20.sp, color: Colors.white),
          ),
        ),
        Positioned(
          right: 10.w,
          bottom: -20.w,
          child: ContactAvatar(
            contactId: _userId,
            size: 60,
            shape: .rectangle,
          ),
        ),
      ],
    );
  }

  // 预览背景图片
  void _previewBackground() {
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
                  '${GlobalConstants.momentsBackgroundUrl}/$_userId.jpg?v=$_bgVersion',
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'moments_bg_$_userId',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 修改朋友圈背景（仅自己）
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

  // 显示修改背景sheet（仅自己）
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

  // 构建页面头部（覆盖在背景上方）
  Widget _buildPageHeader() {
    return PageHeader(
      title: _isTopVisible ? '' : _nickname,
      showLeftBackIcon: true,
      showRightIcon: false,
      backgroundColor: _isTopVisible
          ? Colors.transparent
          : Color.fromRGBO(227, 227, 227, 1),
      showBorder: false,
      iconColor: _isTopVisible ? Colors.white : Colors.black,
    );
  }

  // 构建回到顶部悬浮按钮（顶部不可见时显示）
  Widget _buildFloatButton() {
    if (_isTopVisible) return const SizedBox.shrink();
    return Positioned(
      right: 15.w,
      bottom: 80.w,
      child: GestureDetector(
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

  // 构建空状态
  Widget _buildEmptyContent() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 50.w),
      child: Column(
        spacing: 10.w,
        children: [
          Icon(Icons.photo_camera, size: 60.w, color: Colors.grey),
          Text(
            _isSelf ? '你还没有发布过动态' : 'TA还没有发布过动态',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEmpty = _posts.isEmpty && !_isRefreshing;
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
          children: [
            RefreshIndicator(
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
            ),
            _buildPageHeader(),
            _buildFloatButton(),
          ],
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
