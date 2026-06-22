import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 联系人选择
class ContactSelectPage extends StatefulWidget {
  const ContactSelectPage({super.key});

  @override
  State<ContactSelectPage> createState() => _ContactSelectPageState();
}

class _ContactSelectPageState extends State<ContactSelectPage> {
  // 要搜索的内容
  String _searchText = '';
  // 搜索框控制器
  final _searchController = TextEditingController();
  // 联系人store
  final _contactStore = Get.find<UserContactController>();
  // 测试数据
  final List<UserContactRes> testContacts = [
    // 中文姓名（覆盖多音字、生僻字）
    UserContactRes(contactId: "1", contactName: "张三"),
    UserContactRes(contactId: "2", contactName: "李四"),
    UserContactRes(contactId: "3", contactName: "王五"),
    UserContactRes(contactId: "4", contactName: "赵六"),
    UserContactRes(contactId: "5", contactName: "重庆小面"), // “重”多音字，取 C
    UserContactRes(contactId: "6", contactName: "长安汽车"), // “长”多音字，取 C
    UserContactRes(contactId: "7", contactName: "曾小贤"), // “曾”多音字，取 Z（默认）
    UserContactRes(contactId: "8", contactName: "陈真"),
    UserContactRes(contactId: "9", contactName: "丁一"),
    UserContactRes(contactId: "10", contactName: "欧阳菲菲"), // 复姓，取“欧” O
    // 英文姓名（大小写混合）
    UserContactRes(contactId: "11", contactName: "Alice"),
    UserContactRes(contactId: "12", contactName: "Bob"),
    UserContactRes(contactId: "13", contactName: "Charlie"),
    UserContactRes(contactId: "14", contactName: "David"),
    UserContactRes(contactId: "15", contactName: "Eva"),
    UserContactRes(contactId: "16", contactName: "Frank"),
    UserContactRes(contactId: "17", contactName: "Grace"),
    UserContactRes(contactId: "18", contactName: "Henry"),
    UserContactRes(contactId: "19", contactName: "iris"), // 小写开头，应归入 I
    UserContactRes(contactId: "20", contactName: "jack"), // 小写开头，应归入 J
    // 数字开头（归入 #）
    UserContactRes(contactId: "21", contactName: "10086客服"),
    UserContactRes(contactId: "22", contactName: "12345热线"),
    UserContactRes(contactId: "23", contactName: "007特工"),

    // 特殊字符开头（归入 #）
    UserContactRes(contactId: "24", contactName: "_内部测试"),
    UserContactRes(contactId: "25", contactName: "-连字符"),
    UserContactRes(contactId: "26", contactName: "#管理员"),
    UserContactRes(contactId: "27", contactName: "@At符号"),
    UserContactRes(contactId: "28", contactName: "·中间点"), // 非标准字符，归入 #
    // 纯数字/符号（归入 #）
    UserContactRes(contactId: "29", contactName: "123"),
    UserContactRes(contactId: "30", contactName: "---"),
  ];
  // 联系人分组数据
  late final Map<String, List<UserContactRes>> _group;
  // 排序后的分组 Key 列表
  late List<String> _groupKeys;
  // 每个分组对应的 GlobalKey
  late Map<String, GlobalKey> _groupKeyMap;
  // 索引栏key, 用于获取尺寸
  final _indexBarKey = GlobalKey();
  // 记录上一次触摸的字母，防止重复跳转
  String? _lastTouchLetter;

  @override
  void initState() {
    super.initState();
    // 初始化
    _group = getGroupedContacts(testContacts);
    _groupKeys = _group.keys.toList();
    _groupKeyMap = {for (final key in _groupKeys) key: GlobalKey()};
  }

  // 构建搜索框
  Widget _buildSearch() {
    return Container(
      color: Color.fromRGBO(237, 237, 237, 1),
      alignment: .center,
      padding: EdgeInsets.only(bottom: 10.w, left: 15.w, right: 15.w),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        onSubmitted: (value) {
          print('搜索: $_searchText');
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
              color: Color.fromRGBO(131, 131, 136, 1),
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
                      });
                    },
                    child: Container(
                      width: 22.w,
                      height: 22.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(178, 178, 178, 1),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.close, color: Colors.white, size: 15.w),
                    ),
                  ),
                )
              : SizedBox(),
          suffixIconConstraints: BoxConstraints(),
          contentPadding: EdgeInsets.symmetric(vertical: 6.w),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          hintText: '搜索',
          hintStyle: TextStyle(
            color: Color.fromRGBO(178, 178, 178, 1),
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
  Widget _buildContactItem(UserContactRes data) {
    return InkClick(
      backgroundColor: Colors.white,
      onTap: () {
        Navigator.pop(context, data.contactId);
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
                      color: Color.fromRGBO(232, 232, 232, 1),
                      width: 1.w,
                    ),
                  ),
                ),
                child: Container(
                  height: 40.w,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.contactName,
                    style: TextStyle(color: Colors.black, fontSize: 15.w),
                  ),
                ),
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
              color: Color.fromRGBO(114, 114, 114, 1),
            ),
          ),
        ),
        ...List.generate(
          list.length,
          (index) => _buildContactItem(list[index]),
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
                        color: Color.fromRGBO(204, 204, 204, 1),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Color.fromRGBO(237, 237, 237, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color.fromRGBO(237, 237, 237, 1), // 顶部状态栏背景颜色
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color.fromRGBO(
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
              backgroundColor: Color.fromRGBO(237, 237, 237, 1),
              showLeftAvatar: false,
              showRightIcon: false,
              showLeftBackIcon: true,
              showBorder: false,
            ),
            _buildSearch(),
            Expanded(
              child: Stack(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
