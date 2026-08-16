import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/user.dart';
import 'package:zchat/widgets/highlight_text.dart';

// 查找聊天记录页面
class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  // 用户store
  final _userController = Get.find<UserController>();

  // 联系人id
  String _contactId = '';

  // 搜索输入框控制器
  final _searchController = TextEditingController();

  // 滚动控制器
  final _scrollController = ScrollController();

  // 搜索结果列表
  final List<ChatMessageRes> _msgList = [];

  // 当前关键字
  String _keyword = '';
  // 当前页码
  int _page = 1;
  // 是否正在搜索（用于空状态显示）
  bool _isSearching = false;
  // 是否正在加载更多（防并发）
  bool _isLoadingMore = false;
  // 是否还有更多
  bool _hasMore = true;
  // 是否已经搜索过（用于显示空状态）
  bool _isSearched = false;

  // 每页条数
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        // 接收路由参数
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
      }
    });
    _scrollController.addListener(_onScroll);
  }

  // 滚动触底加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100.w) {
      _loadMore();
    }
  }

  // 搜索
  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      return;
    }
    // 收起键盘
    FocusScope.of(context).unfocus();
    setState(() {
      _keyword = keyword;
      _page = 1;
      _hasMore = true;
      _isSearched = true;
      _isSearching = true;
      _msgList.clear();
    });
    await _loadMore();
    setState(() => _isSearching = false);
  }

  // 加载更多
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _keyword.isEmpty) {
      return;
    }
    _isLoadingMore = true;
    try {
      final res = await searchChatMessageApi(
        SearchMsgReq(
          keyword: _keyword,
          contactId: _contactId,
          page: _page,
          pageSize: _pageSize,
        ),
      );
      final list = res.list.map((m) => ChatMessageRes.fromJson(m)).toList();
      if (list.isEmpty) {
        _hasMore = false;
        return;
      }
      setState(() {
        _msgList.addAll(list);
        _page++;
        _hasMore = _page <= res.pages;
      });
    } finally {
      _isLoadingMore = false;
    }
  }

  // 构建搜索结果项
  Widget _buildResultItem(ChatMessageRes msg) {
    // 是否普通文件消息
    final isFile = msg.messageType == MessageTypeEnum.file.type;
    // 要展示并高亮的内容（文本消息显示内容，文件消息显示文件名）
    final content = isFile ? msg.fileName ?? '' : msg.messageContent;
    // 计算关键字高亮范围
    final ranges = HighlightHelper.computeHighlightRanges(content, _keyword);
    return GestureDetector(
      onTap: () {
        // 计算会话对端id：
        // 群聊contact_id恒为群id；私聊时消息的contact_id可能是自己（对方发的消息），
        // 此时对端是sendUserId
        final String contactId;
        if (msg.contactType == UserContactTypeEnum.user &&
            msg.sendUserId != _userController.userInfo.value?.userId) {
          contactId = msg.sendUserId ?? msg.contactId;
        } else {
          contactId = msg.contactId;
        }
        // 跳转到消息页面并定位到该消息
        Navigator.pushNamed(
          context,
          RoutePath.chatMessage,
          arguments: {
            'contactId': contactId,
            'contactType': msg.contactType,
            'sessionId': msg.sessionId,
            'targetMessageId': msg.messageId,
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color.fromRGBO(237, 237, 237, 1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          spacing: 10.w,
          children: [
            if (isFile)
              Icon(MyIcon.fileMsg, size: 40.w, color: Colors.grey),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 4.w,
                children: [
                  // 发送者昵称
                  Text(
                    msg.sendUserNickname ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color.fromRGBO(174, 174, 174, 1),
                    ),
                  ),
                  // 内容/文件名（关键字高亮，最多两行）
                  HighlightText(
                    text: content,
                    ranges: ranges,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    normalStyle: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    highlightStyle: TextStyle(
                      fontSize: 16.sp,
                      color: const Color.fromRGBO(20, 134, 237, 1),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatTimestamp(msg.sendTime),
              style: TextStyle(
                fontSize: 12.sp,
                color: Color.fromRGBO(174, 174, 174, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建搜索结果列表
  Widget _buildResultList() {
    // 搜索过但无结果
    if (_isSearched && _msgList.isEmpty && !_isSearching) {
      return Center(
        child: Text(
          '无相关聊天记录',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
      );
    }
    if (_msgList.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _msgList.length + 1,
      itemBuilder: (ctx, index) {
        if (index == _msgList.length) {
          return Container(
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
        return _buildResultItem(_msgList[index]);
      },
    );
  }

  // 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 247, 247, 1),
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(232, 232, 232, 1),
            width: 1.w,
          ),
        ),
      ),
      child: Row(
        spacing: 10.w,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios, size: 20.sp),
          ),
          Expanded(
            child: Container(
              height: 34.w,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                spacing: 5.w,
                children: [
                  Icon(
                    MyIcon.search,
                    size: 18.w,
                    color: Color.fromRGBO(174, 174, 174, 1),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textInputAction: .search,
                      onSubmitted: (_) => _search(),
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: '搜索聊天记录',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: Color.fromRGBO(174, 174, 174, 1),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _search,
            child: Text(
              '搜索',
              style: TextStyle(
                fontSize: 16.sp,
                color: Color.fromRGBO(20, 134, 237, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: const Color.fromRGBO(247, 247, 247, 1),
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: const Color.fromRGBO(247, 247, 247, 1),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildResultList()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
