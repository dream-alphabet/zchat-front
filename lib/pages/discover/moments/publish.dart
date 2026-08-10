import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/widgets/modal.dart';

// 朋友圈发布页面
class MomentsPublishPage extends StatefulWidget {
  const MomentsPublishPage({super.key});

  @override
  State<MomentsPublishPage> createState() => _MomentsPublishPageState();
}

class _MomentsPublishPageState extends State<MomentsPublishPage> {
  // 图片最大数量
  final _maxImageCount = 9;

  // 文本内容
  String _text = '';

  // 图片列表
  final List<XFile> _imageList = [];

  // 是否没有输入任何内容(文本，图片)
  bool get _isEmpty => _text.trim().isEmpty && _imageList.isEmpty;

  // 添加图片
  void _addImage(ImageSource source) async {
    if (_imageList.length >= _maxImageCount) {
      ToastUtils.showGlobalToast(msg: '最多只能上传9张图片');
      return;
    }
    // 选择图片
    final picker = ImagePicker();
    // 最多可以选几张图片
    final limit = _maxImageCount - _imageList.length;
    List<XFile> images = [];
    if (source == ImageSource.gallery) {
      images = await picker.pickMultiImage(limit: limit);
    } else if (source == ImageSource.camera) {
      final image = await picker.pickImage(source: source);
      if (image == null) {
        return;
      }
      images.add(image);
    }
    // 添加图片到图片列表(最多取前MaxCount张)
    setState(() {
      _imageList.addAll(images.take(limit));
      Navigator.pop(context);
    });
  }

  // 构建顶部区域
  Widget _buildTop() {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 15.w, vertical: 10.w),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Text('取消'),
          ),
          Text('朋友圈发布'),
          GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: _isEmpty
                    ? Color.fromRGBO(242, 242, 242, 1)
                    : Color.fromRGBO(20, 134, 237, 1),
                borderRadius: .circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
              child: Text(
                '完成',
                style: TextStyle(
                  color: _isEmpty
                      ? Color.fromRGBO(207, 207, 207, 1)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 文本输入框
  Widget _buildTextInput() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _text = value;
        });
      },
      maxLength: 50,
      maxLines: 3,
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => SizedBox(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: '这一刻的想法...',
        hintStyle: TextStyle(
          fontSize: 16.sp,
          color: Color.fromRGBO(176, 176, 176, 1),
        ),
        border: .none,
        constraints: BoxConstraints(),
        contentPadding: EdgeInsets.all(0),
      ),
      textInputAction: .done,
    );
  }

  // 上传组件
  Widget _buildUpload() {
    return GestureDetector(
      onTap: () {
        showMyBottomSheet(context, [
          SheetItem('从相册中选择图片', () {
            _addImage(ImageSource.gallery);
          }),
          SheetItem('拍照', () {
            _addImage(ImageSource.camera);
          }),
        ]);
      },
      child: Container(
        width: 100.w,
        height: 100.w,
        decoration: BoxDecoration(
          color: Color.fromRGBO(242, 242, 242, 1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.add,
          color: Color.fromRGBO(207, 207, 207, 1),
          size: 32.w,
        ),
      ),
    );
  }

  // 预览图片
  void _previewImage(int index) async {
    final controller = PageController(initialPage: index);
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: PhotoViewGallery.builder(
              pageController: controller,
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(_imageList[index].path)),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: _imageList[index].path,
                  ),
                );
              },
              itemCount: _imageList.length,
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  // 媒体(图片)上传区域
  Widget _buildImageUpload() {
    int count = _imageList.length;
    if (count < _maxImageCount) {
      count++;
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // 禁用内部滚动
      childAspectRatio: 1.0, // 正方形
      crossAxisSpacing: 8.w,
      mainAxisSpacing: 8.w,
      children: List.generate(count, (index) {
        if (index == _imageList.length) {
          return _buildUpload();
        }
        return Hero(
          tag: _imageList[index].path,
          child: GestureDetector(
            onTap: () {
              _previewImage(index);
            },
            child: Image.file(File(_imageList[index].path), fit: .cover),
          ),
        );
      }),
    );
  }

  // 选项配置区域
  Widget _buildConfig() {
    return Text('选项配置区域');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        bottomOpacity: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          children: [
            _buildTop(),
            SizedBox(height: 20.w),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 25.w),
              child: Column(
                crossAxisAlignment: .start,
                spacing: 10.w,
                children: [
                  _buildTextInput(),
                  _buildImageUpload(),
                  _buildConfig(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
