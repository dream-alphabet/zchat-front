import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 发现
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // 朋友圈
  Widget _buildMoments() {
    return InkClick(
      backgroundColor: Colors.white,
      onTap: () {
        Navigator.pushNamed(context, '/moments');
      },
      child: Container(
        height: 60.w,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Row(
          children: [
            Image.asset(
              'lib/assets/images/moments.png',
              width: 20.w,
              height: 20.w,
            ),
            SizedBox(width: 20.w),
            Expanded(child: Text('朋友圈')),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.w),
              child: Image.asset(
                'lib/assets/test/01.png',
                width: 30.w,
                height: 30.w,
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              MyIcon.arrowRight,
              color: Color.fromRGBO(179, 179, 179, 1),
              size: 15.w,
            ),
          ],
        ),
      ),
    );
  }

  // 扫一扫
  Widget _buildScan() {
    return InkClick(
      backgroundColor: Colors.white,
      onTap: () {
        Navigator.pushNamed(context, '/scan');
      },
      child: Container(
        height: 60.w,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Row(
          children: [
            Icon(
              MyIcon.scan,
              size: 20.w,
              color: Color.fromRGBO(20, 134, 237, 1),
            ),
            SizedBox(width: 20.w),
            Expanded(child: Text('扫一扫')),
            SizedBox(width: 10.w),
            Icon(
              MyIcon.arrowRight,
              color: Color.fromRGBO(179, 179, 179, 1),
              size: 15.w,
            ),
          ],
        ),
      ),
    );
  }

  // 发现功能列表
  Widget _buildDiscoverItems() {
    return Column(spacing: 10.w, children: [_buildMoments(), _buildScan()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(237, 237, 237, 1),
      body: Column(
        children: [
          PageHeader(title: '发现'),
          _buildDiscoverItems(),
        ],
      ),
    );
  }
}

class DiscoverListItemData {
  final IconData icon;
  final String name;
  final String path;
  final bool hasImage;
  final String image;

  DiscoverListItemData({
    required this.icon,
    required this.name,
    required this.path,
    this.hasImage = false,
    this.image = '',
  });
}
