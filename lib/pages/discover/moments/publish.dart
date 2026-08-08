import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
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
  List<XFile> _imageList = [];

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
    List<XFile> images = [];
    if (source == ImageSource.gallery) {
      images = await picker.pickMultiImage(
        limit: _maxImageCount - _imageList.length,
      );
      print('选择了${images.length}张图片');
    } else if (source == ImageSource.camera) {
      final image = await picker.pickImage(source: source);
      if (image == null) {
        return;
      }
    }
    // 添加图片到图片列表
    _imageList.addAll(images);
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

  // 媒体(图片)上传区域
  Widget _buildImageUpload() {
    return _buildUpload();
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
