import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/api/group.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/highlight_text.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 联系人选择
class ContactSelectPage extends StatefulWidget {
  // 选中联系人事件
  final Future<bool> Function(UserContactRes contact)? onSelect;

  const ContactSelectPage({super.key, this.onSelect});

  @override
  State<ContactSelectPage> createState() => _ContactSelectPageState();
}

class _ContactSelectPageState extends State<ContactSelectPage> {
  // 要搜索的内容
  String _searchText = '';
  // 搜索结果
  List<UserContactRes> _searchResult = [];
  // 要查找的联系人类型(默认为好友)
  int? _contactType = UserContactTypeEnum.user;
  // 搜索框控制器
  final _searchController = TextEditingController();
  // 联系人store
  final _contactStore = Get.find<UserContactController>();
  // 联系人分组数据
  Map<String, List<UserContactRes>> _group = {};
  // 排序后的分组 Key 列表
  List<String> _groupKeys = [];
  // 每个分组对应的 GlobalKey
  Map<String, GlobalKey> _groupKeyMap = {};
  // 索引栏key, 用于获取尺寸
  final _indexBarKey = GlobalKey();
  // 记录上一次触摸的字母，防止重复跳转
  String? _lastTouchLetter;
  // 防抖工具类
  final _debouncer = Debouncer(timeout: Duration(milliseconds: 300));
  // 是否是查询群聊成员
  bool _isSearchGroupMember = false;
  // 群聊id
  String _groupId = '';
  // 是否是多选模式
  bool _multiSelect = false;
  // 多选模式中已选中的联系人ID集合
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      List<UserContactRes> contactList = [..._contactStore.userList];
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        // 如果是查找群成员
        if (params != null && params['groupId'] != null) {
          contactList = params['contactList'];
          _groupId = params['groupId'];
          _isSearchGroupMember = true;
        }
        // 如果是查找所有
        if (params != null && params['searchAll'] == true) {
          _contactType = null;
          // 拼接群聊列表
          contactList.addAll(_contactStore.groupList);
        }
        // 多选模式
        if (params != null && params['multiSelect'] == true) {
          _multiSelect = true;
          final preSelected = params['selectedIds'] as List<String>?;
          if (preSelected != null) {
            _selectedIds.addAll(preSelected);
          }
        }
      }
      // 初始化
      _group = getGroupedContacts(contactList);
      _groupKeys = _group.keys.toList();
      _groupKeyMap = {for (final key in _groupKeys) key: GlobalKey()};
      setState(() {});
    });
  }

  // 搜索联系人
  void _searchContact() async {
    // 关键词不能为空
    if (_searchText.trim().isEmpty) {
      return ToastUtils.showGlobalToast(msg: '搜索内容不能为空');
    }
    // 搜索关键词
    final keywords = _searchText.trim();
    if (_isSearchGroupMember) {
      // 搜索群成员
      _searchResult = await searchGroupMemberApi(_groupId, keywords);
    } else {
      _searchResult = await searchContactApi(
        SearchContactReq(keywords: keywords, contactType: _contactType),
      );
    }
    setState(() {});
  }

  // 构建搜索框
  Widget _buildSearch() {
    return Container(
      color: const Color.fromRGBO(237, 237, 237, 1),
      alignment: .center,
      padding: EdgeInsets.only(bottom: 10.w, left: 15.w, right: 15.w),
      child: TextField(
        onChanged: (value) {
          _searchText = value;
          // 使用防抖来调用工具方法
          _debouncer.run(() {
            if (_searchText.trim().isNotEmpty) {
              _searchContact();
            } else {
              // 清空搜索结果
              setState(() {
                _searchResult = [];
              });
            }
          });
        },
        onSubmitted: (value) {
          _searchContact();
        },
        autofocus: false,
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: Colors.black, fontSize: 16.sp),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 8.w, right: 5.w),
            child: Icon(
              Icons.search_outlined,
              size: 22.w,
              color: const Color.fromRGBO(131, 131, 136, 1),
            ),
          ),
          prefixIconConstraints: BoxConstraints(),
          suffixIcon: _searchText.isNotEmpty
              ? Padding(
                  padding: EdgeInsetsGeometry.only(right: 8.w),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchText = '';
                        // 清空输入框内容
                        _searchController.clear();
                        _searchResult.clear();
                      });
                    },
                    child: Container(
                      width: 22.w,
                      height: 22.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromRGBO(178, 178, 178, 1),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.close, color: Colors.white, size: 15.w),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          suffixIconConstraints: BoxConstraints(),
          contentPadding: EdgeInsets.symmetric(vertical: 6.w),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          hintText: '搜索',
          hintStyle: TextStyle(
            color: const Color.fromRGBO(178, 178, 178, 1),
            fontSize: 16.sp,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  // 构建联系人列表项
  Widget _buildContactItem(
    UserContactRes data, {
    List<HighlightRange>? highlightRanges,
    bool showCheckbox = false,
  }) {
    final isSelected = _selectedIds.contains(data.contactId);

    return InkClick(
      backgroundColor: Colors.white,
      onTap: () async {
        if (showCheckbox) {
          // 多选模式：切换选中状态
          setState(() {
            if (isSelected) {
              _selectedIds.remove(data.contactId);
            } else {
              _selectedIds.add(data.contactId);
            }
          });
          return;
        }
        // 单选模式：保持原有逻辑
        if (widget.onSelect != null) {
          final shouldPop = await widget.onSelect!(data);
          if (shouldPop) {
            Navigator.pop(context, data.contactId);
          }
        } else {
          Navigator.pop(context, data);
        }
      },
      child: Container(
        padding: EdgeInsets.only(left: 15.w),
        child: Row(
          spacing: 15.w,
          children: [
            ContactAvatar(contactId: data.contactId),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color.fromRGBO(232, 232, 232, 1),
                      width: 1.w,
                    ),
                  ),
                ),
                child: Container(
                  height: 40.w,
                  alignment: Alignment.centerLeft,
                  child: highlightRanges != null && highlightRanges.isNotEmpty
                      ? HighlightText(
                          text: data.remark == null
                              ? data.originName
                              : '${data.remark}(${data.originName})',
                          normalStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 15.w,
                          ),
                          highlightStyle: TextStyle(
                            color: const Color.fromRGBO(20, 134, 237, 1),
                            fontSize: 15.w,
                          ),
                          ranges: highlightRanges,
                        )
                      : Text(
                          data.contactName,
                          style: TextStyle(color: Colors.black, fontSize: 15.w),
                        ),
                ),
              ),
            ),
            // 多选模式显示复选框
            if (showCheckbox)
              Padding(
                padding: EdgeInsets.only(right: 15.w),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? const Color.fromRGBO(20, 134, 237, 1)
                      : const Color.fromRGBO(199, 199, 204, 1),
                  size: 22.w,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 构建联系人块
  Widget _buildContactPart(String key) {
    final list = _group[key]!;
    return Column(
      key: _groupKeyMap[key],
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: EdgeInsetsGeometry.all(10.w),
          child: Text(
            key,
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color.fromRGBO(114, 114, 114, 1),
            ),
          ),
        ),
        ...List.generate(
          list.length,
          (index) => _buildContactItem(list[index],
              showCheckbox: _multiSelect),
        ),
      ],
    );
  }

  // 构建联系人列表
  Widget _buildContactList() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(
          _groupKeys.length,
          (index) => _buildContactPart(_groupKeys[index]),
        ),
      ),
    );
  }

  // 滚动到指定字母的位置
  void _scrollToKey(String letter) {
    final context = _groupKeyMap[letter]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: Duration(milliseconds: 300));
    }
  }

  // 处理索引栏滑动
  void _handleIndexBarDrag(double localDy) {
    // 获取索引栏的渲染盒
    final RenderBox? box =
        _indexBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final height = box.size.height;
    if (height <= 0) return;

    const int letterCount = 27; // A~Z + #
    double itemHeight = height / letterCount; // 每个字母平均高度
    // 计算滑动到了哪一个字母
    int index = (localDy / itemHeight).floor();
    // 边界处理
    if (index < 0) index = 0;
    if (index >= letterCount) index = letterCount - 1;
    String letter = index < 26
        ? String.fromCharCode('A'.codeUnitAt(0) + index)
        : '#';
    // 只有字母改变了才滚动
    if (_lastTouchLetter != letter) {
      _lastTouchLetter = letter;
      _scrollToKey(letter);
      setState(() {});
    }
  }

  // 构建索引栏
  Widget _buildIndexBar() {
    // 固定字母列表：A~Z + #
    List<String> letters = List.generate(
      26,
      (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
    );
    letters.add('#');
    return GestureDetector(
      key: _indexBarKey,
      onVerticalDragStart: (details) {
        _handleIndexBarDrag(details.localPosition.dy);
      },
      onVerticalDragUpdate: (details) {
        _handleIndexBarDrag(details.localPosition.dy);
      },
      onVerticalDragEnd: (details) {
        setState(() {
          _lastTouchLetter = null;
        });
      },
      child: Container(
        padding: EdgeInsets.only(right: 8.w),
        child: Column(
          mainAxisAlignment: .center,
          children: letters.map((letter) {
            // 是否有联系人
            bool exists = _group.containsKey(letter);
            return Stack(
              clipBehavior: .none,
              children: [
                GestureDetector(
                  onTap: exists ? () => _scrollToKey(letter) : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 1.w),
                    child: Text(
                      letter,
                      style: TextStyle(fontSize: 11.sp, color: Colors.black),
                    ),
                  ),
                ),
                // 滑动到对应字母时显示
                if (_lastTouchLetter == letter)
                  Positioned(
                    top: -9.w,
                    right: 11.sp + 15.w,
                    child: Container(
                      alignment: .center,
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(204, 204, 204, 1),
                        shape: .circle,
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: .bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // 构建搜索结果区域
  Widget _buildSearchResult() {
    // 搜索关键词
    final keyword = _searchText.trim();
    return Column(
      children: List.generate(_searchResult.length, (index) {
        final item = _searchResult[index];
        // 计算高亮范围
        final ranges = HighlightHelper.computeHighlightRanges(
          item.remark == null
              ? item.originName
              : '${item.remark}(${item.originName})',
          keyword,
        );
        return _buildContactItem(item,
            highlightRanges: ranges, showCheckbox: _multiSelect);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: const Color.fromRGBO(237, 237, 237, 1), // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: const Color.fromRGBO(
            237,
            237,
            237,
            1,
          ), // 底部导航栏背景颜色
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '选择联系人',
              backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
              showLeftAvatar: false,
              showRightIcon: _multiSelect,
              showLeftBackIcon: true,
              showBorder: false,
              rightIconList: _multiSelect
                  ? [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(
                              context, _selectedIds.toList());
                        },
                        child: Text(
                          '完成${_selectedIds.isNotEmpty ? '(${_selectedIds.length})' : ''}',
                          style: TextStyle(
                            color: _selectedIds.isNotEmpty
                                ? const Color.fromRGBO(20, 134, 237, 1)
                                : const Color.fromRGBO(167, 167, 167, 1),
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ]
                  : [],
            ),
            _buildSearch(),
            Expanded(
              child: _searchText.trim().isEmpty
                  ? Stack(
                      children: [
                        _buildContactList(),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            behavior: .opaque, // 覆盖所有索引栏区域, 拦截事件
                            child: _buildIndexBar(),
                          ),
                        ),
                      ],
                    )
                  : _buildSearchResult(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
