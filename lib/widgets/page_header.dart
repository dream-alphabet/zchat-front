import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/constants.dart';

// 页面头部组件
class PageHeader extends StatefulWidget {
  final String title;
  final bool showRightIcon;
  final bool showLeftBackIcon;
  final bool showBorder;
  final Color backgroundColor;
  final void Function()? onBack;

  const PageHeader({
    required this.title,
    this.showRightIcon = true,
    this.showLeftBackIcon = false,
    this.showBorder = true,
    this.backgroundColor = const Color.fromRGBO(247, 247, 247, 1),
    this.onBack,
    super.key,
  });

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  // 构建右侧图标列表
  Widget _buildIconList() {
    return Row(
      spacing: 20.w,
      children: [
        Icon(MyIcon.search, size: 22.w),
        // Icon(MyIcon.add, size: 22.w),
        PopupMenuButton<String>(
          // 自定义图标
          icon: Icon(MyIcon.add, size: 22.w),
          // 弹出位置
          offset: Offset(0, 40.w),
          // 圆角
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          // 颜色
          color: Colors.white,
          menuPadding: EdgeInsets.all(0),
          // 菜单项
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.w),
              value: RoutePath.createGroup,
              child: Row(
                children: [
                  Icon(MyIcon.groupChat, color: Color.fromRGBO(0, 95, 255, 1), size: 26.w),
                  SizedBox(width: 12.w),
                  Text('发起群聊', style: TextStyle(color: Colors.black, fontSize: 15.w)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.w),
              value: RoutePath.addFriend,
              child: Row(
                children: [
                  Icon(MyIcon.newFriend, color: Color.fromRGBO(0, 95, 255, 1), size: 26.w),
                  SizedBox(width: 12.w),
                  Text('添加朋友', style: TextStyle(color: Colors.black, fontSize: 15.w)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.w),
              value: RoutePath.scan,
              child: Row(
                children: [
                  Icon(MyIcon.scan, color: Color.fromRGBO(0, 95, 255, 1), size: 26.w),
                  SizedBox(width: 12.w),
                  Text('扫一扫', style: TextStyle(color: Colors.black, fontSize: 15.w)),
                ],
              ),
            ),
          ],
          onSelected: (String value) {
            Navigator.pushNamed(context, value);
          },
        ),
      ],
    );
  }

  // 构建左侧返回图标
  Widget _buildLeftBackIcon() {
    return GestureDetector(
      onTap: () {
        // 如果没有传递onBack，默认回退上一页
        final onBack = widget.onBack;
        if (onBack != null) {
          onBack();
          return;
        }
        Navigator.pop(context);
      },
      child: Icon(Icons.arrow_back_ios, size: 20.sp),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 56.w,
          decoration: BoxDecoration(
            border: Border(
              bottom: widget.showBorder ? BorderSide(
                color: Color.fromRGBO(232, 232, 232, 1),
                width: 1.w,
              ) : BorderSide.none,
            ),
            color: widget.backgroundColor,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
            ),
          ),
        ),
        if (widget.showLeftBackIcon)
          Positioned(
            top: 0,
            bottom: 0,
            left: 15.w,
            child: Center(child: _buildLeftBackIcon()),
          ),
        if (widget.showRightIcon)
          Positioned(
            top: 0,
            bottom: 0,
            right: 15.w,
            child: Center(child: _buildIconList()),
          ),
      ],
    );
  }
}
