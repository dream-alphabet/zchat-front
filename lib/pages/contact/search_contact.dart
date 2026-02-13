import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/widgets/ink_click.dart';

// 搜索好友(用户/群聊)
class SearchContactPage extends StatefulWidget {
  const SearchContactPage({super.key});

  @override
  State<SearchContactPage> createState() => _SearchContactPageState();
}

class _SearchContactPageState extends State<SearchContactPage> {
  // 要搜索的内容
  String _searchText = '';
  // 搜索框控制器
  final _searchController = TextEditingController();

  // 搜索
  Future<void> _search() async {
    // 搜索内容不能为空
    if (_searchText.isEmpty) {
      return ToastUtils.showGlobalToast(msg: '搜索内容不能为空');
    }
    // 搜索
    final exists = await searchContactExistApi(_searchText);
    if (!exists) {
      return ToastUtils.showGlobalToast(msg: '用户/群组不存在');
    }
    Navigator.pushNamed(
      context,
      RoutePath.contactInfo,
      arguments: {'contactId': _searchText},
    );
  }

  // 搜索框
  Widget _buildSearch() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w),
      child: Row(
        spacing: 14.w,
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              onSubmitted: (value) {
                _search();
              },
              autofocus: true,
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
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 15.w,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(),
                suffixIconConstraints: BoxConstraints(),
                contentPadding: EdgeInsets.symmetric(vertical: 6.w),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                hintText: '搜索 邮箱/用户id/群id',
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
          ),
          GestureDetector(
            onTap: () {
              // 隐藏软键盘
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: Text(
              '取消',
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

  // 搜索内容
  Widget _buildSearchContent() {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w, vertical: 8.w),
      child: Row(
        spacing: 10.w,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Color.fromRGBO(20, 134, 237, 1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Icon(MyIcon.newFriend, size: 20.w, color: Colors.white),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '搜索:'),
                TextSpan(
                  text: _searchText,
                  style: TextStyle(color: Color.fromRGBO(20, 134, 237, 1)),
                ),
              ],
              style: TextStyle(color: Colors.black, fontSize: 16.sp),
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
        backgroundColor: Color.fromRGBO(237, 237, 237, 1),
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color.fromRGBO(237, 237, 237, 1),
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color.fromRGBO(237, 237, 237, 1), // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Color.fromRGBO(237, 237, 237, 1),
      body: Column(
        spacing: 10.w,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearch(),
          if (_searchText.isNotEmpty)
            InkClick(
              onTap: _search,
              backgroundColor: Colors.white,
              child: _buildSearchContent(),
            ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // 隐藏软键盘
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              child: SizedBox(width: double.infinity, height: double.infinity),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
