import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/icon.dart';

// 页面头部组件
class PageHeader extends StatefulWidget {
  final String title;
  final bool showRightIcon;
  final bool showLeftBackIcon;
  final void Function()? onBack;

  const PageHeader({required this.title, this.showRightIcon = true, this.showLeftBackIcon = false, this.onBack, super.key});

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  // 构建右侧图标列表
  Widget _buildIconList() {
    return Row(spacing: 20.w, children: [Icon(MyIcon.search, size: 20.sp), Icon(MyIcon.add, size: 20.sp)]);
  }

  // 构建左侧返回图标
  Widget _buildLeftBackIcon() {
    return GestureDetector(
      onTap: () {
        // 如果没有传递onBack，默认回退上一页
        final onBack = widget.onBack;
        if(onBack != null) {
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
              bottom: BorderSide(
                color: Color.fromRGBO(232, 232, 232, 1),
                width: 1.w,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if(widget.showLeftBackIcon) Positioned(
          top: 0,
          bottom: 0,
          left: 15.w,
          child: Center(child: _buildLeftBackIcon())
        ),
        if(widget.showRightIcon) Positioned(
          top: 0,
          bottom: 0,
          right: 15.w,
          child: Center(child: _buildIconList()),
        ),
      ],
    );
  }
}
