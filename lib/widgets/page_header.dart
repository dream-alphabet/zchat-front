import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/animation.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/pages/my/my.dart';
import 'package:zchat/widgets/contact_avatar.dart';

// 页面头部组件
class PageHeader extends StatefulWidget {
  final String title;
  // 是否显示右侧图标
  final bool showRightIcon;
  // 是否显示左侧返回图标
  final bool showLeftBackIcon;
  // 是否显示左侧用户头像
  final bool showLeftAvatar;
  // 用户id
  final String? userId;
  final bool showBorder;
  final Color backgroundColor;
  final void Function()? onBack;
  final List<Widget> rightIconList;

  const PageHeader({
    required this.title,
    this.showRightIcon = true,
    this.showLeftBackIcon = false,
    this.showLeftAvatar = false,
    this.userId,
    this.showBorder = true,
    this.backgroundColor = const Color.fromRGBO(247, 247, 247, 1),
    this.onBack,
    this.rightIconList = const [],
    super.key,
  });

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  // 构建右侧图标列表(默认是搜索和添加图标，可以通过rightIconList属性覆盖)
  Widget _buildIconList() {
    return Row(
      spacing: 10.w,
      children: widget.rightIconList.isEmpty
          ? [
              GestureDetector(
                onTap: () {
                  // 跳转到搜索联系人页面
                  Navigator.pushNamed(context, RoutePath.searchContact);
                },
                child: Icon(MyIcon.search, size: 25.w),
              ),
              PopupMenuButton<String>(
                // 自定义图标
                icon: Icon(MyIcon.add, size: 25.w),
                // 弹出位置
                offset: Offset(0, 40.w),
                // 圆角
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                // 颜色
                color: Colors.white,
                menuPadding: EdgeInsets.all(0),
                // 菜单项
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 12.w,
                    ),
                    value: RoutePath.createGroup,
                    child: Row(
                      children: [
                        Icon(
                          MyIcon.groupChat,
                          color: Color.fromRGBO(0, 95, 255, 1),
                          size: 26.w,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '创建群聊',
                          style: TextStyle(color: Colors.black, fontSize: 15.w),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 12.w,
                    ),
                    value: RoutePath.addFriend,
                    child: Row(
                      children: [
                        Icon(
                          MyIcon.newFriend,
                          color: Color.fromRGBO(0, 95, 255, 1),
                          size: 26.w,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '添加朋友',
                          style: TextStyle(color: Colors.black, fontSize: 15.w),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 12.w,
                    ),
                    value: RoutePath.scan,
                    child: Row(
                      children: [
                        Icon(
                          MyIcon.scan,
                          color: Color.fromRGBO(0, 95, 255, 1),
                          size: 26.w,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '扫一扫',
                          style: TextStyle(color: Colors.black, fontSize: 15.w),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (String value) {
                  Navigator.pushNamed(context, value);
                },
              ),
            ]
          : widget.rightIconList,
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

  // 构建左侧用户头像
  Widget _buildLeftAvatar() {
    return GestureDetector(
      onTap: () {
        // 跳转到用户中心页面
        Navigator.push(
          context,
          RouteUtils.slideRight(
            (ctx) => MyPage(),
            settings: RouteSettings(name: RoutePath.my),
          ),
        );
      },
      child: ContactAvatar(contactId: widget.userId ?? '-1'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 50.w,
          decoration: BoxDecoration(
            border: Border(
              bottom: widget.showBorder
                  ? BorderSide(
                      color: Color.fromRGBO(232, 232, 232, 1),
                      width: 1.w,
                    )
                  : BorderSide.none,
            ),
            color: widget.backgroundColor,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.title,
            style: TextStyle(color: Colors.black, fontSize: 16.sp),
          ),
        ),
        if (widget.showLeftBackIcon)
          Positioned(
            top: 0,
            bottom: 0,
            left: 25.w,
            child: Center(child: _buildLeftBackIcon()),
          ),
        if (widget.showLeftAvatar)
          Positioned(
            top: 0,
            bottom: 0,
            left: 15.w,
            child: Center(child: _buildLeftAvatar()),
          ),
        if (widget.showRightIcon)
          Positioned(
            top: 0,
            bottom: 0,
            right: 25.w,
            child: Center(child: _buildIconList()),
          ),
      ],
    );
  }
}
