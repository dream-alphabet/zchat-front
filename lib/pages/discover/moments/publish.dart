import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:zchat/api/moments.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/stores/contact.dart';
import 'package:zchat/widgets/contact_avatar.dart';
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

  // 文本输入框焦点控制器
  final _focusNode = FocusNode();

  // 图片列表
  final List<XFile> _imageList = [];

  // 可见类型: 0-公开, 1-私密, 2-部分可见, 3-不给谁看
  int _visibleType = 0;

  // 可见类型为2或3时选中的联系人ID列表
  List<String> _visibleUserIds = [];

  // 联系人store（用于获取联系人信息）
  final _contactStore = Get.find<UserContactController>();

  // 选中的联系人信息（从store中查找）
  List<UserContactRes> get _visibleContacts {
    return _visibleUserIds
        .map((id) => _contactStore.getUserContact(id))
        .where((c) => c != null)
        .cast<UserContactRes>()
        .toList();
  }

  // 可见类型选项
  static const List<Map<String, dynamic>> _visibleOptions = [
    {'label': '公开', 'desc': '所有人可见', 'value': 0},
    {'label': '私密', 'desc': '仅自己可见', 'value': 1},
    {'label': '部分可见', 'desc': '选中的朋友可见', 'value': 2},
    {'label': '不给谁看', 'desc': '选中的朋友不可见', 'value': 3},
  ];

  // 是否正在发布中
  bool _isPublishing = false;

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

  // 发布动态
  Future<void> _publish() async {
    if (_isEmpty || _isPublishing) return;
    setState(() => _isPublishing = true);
    try {
      // 构建可见用户JSON
      String? visibleUsers;
      if ((_visibleType == 2 || _visibleType == 3) &&
          _visibleUserIds.isNotEmpty) {
        visibleUsers = '[${_visibleUserIds.map((id) => '"$id"').join(',')}]';
      }
      // 构建文件列表
      final files = _imageList
          .map((f) => MultipartFile.fromFileSync(f.path, filename: f.name))
          .toList();
      await publishMomentsApi(
        content: _text.trim(),
        files: files,
        visibleType: _visibleType,
        visibleUsers: visibleUsers,
      );
      ToastUtils.showGlobalToast(msg: '发布成功');
      Navigator.pop(context);
    } catch (_) {
      // request.dart 已处理toast提示
      setState(() => _isPublishing = false);
    }
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
            onTap: _publish,
            child: Container(
              decoration: BoxDecoration(
                color: _isEmpty || _isPublishing
                    ? Color.fromRGBO(242, 242, 242, 1)
                    : Color.fromRGBO(20, 134, 237, 1),
                borderRadius: .circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
              child: _isPublishing
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color.fromRGBO(20, 134, 237, 1),
                      ),
                    )
                  : Text(
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
      focusNode: _focusNode,
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
      autofocus: false,
    );
  }

  // 上传按钮
  Widget _buildUpload({Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () {
        _focusNode.unfocus();
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

  // 删除图片
  void _removeImage(int index) {
    setState(() {
      _imageList.removeAt(index);
    });
  }

  // 构建单张图片项（含右上角删除按钮）
  Widget _buildImageItem(int index, {required Key key}) {
    final imageFile = _imageList[index];
    return Stack(
      key: key,
      clipBehavior: Clip.none,
      children: [
        // 图片缩略图
        Hero(
          tag: imageFile.path,
          child: GestureDetector(
            onTap: () => _previewImage(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                File(imageFile.path),
                width: 100.w,
                height: 100.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // 右上角删除按钮
        Positioned(
          top: -6.w,
          right: -6.w,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 14.w),
            ),
          ),
        ),
      ],
    );
  }

  // 媒体(图片)上传区域（支持拖拽排序）
  Widget _buildImageUpload() {
    final bool showUpload = _imageList.length < _maxImageCount;
    return ReorderableGridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // 禁用内部滚动
      childAspectRatio: 1.0, // 正方形
      crossAxisSpacing: 8.w,
      mainAxisSpacing: 8.w,
      clipBehavior: Clip.none, // 允许关闭按钮溢出
      // 上传按钮放在footer中，不会被包装为可拖拽项
      footer: showUpload
          ? [_buildUpload(key: const ValueKey('__upload__'))]
          : null,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final item = _imageList.removeAt(oldIndex);
          // 此package的newIndex已经是移除后的目标位置，无需再调整
          _imageList.insert(newIndex, item);
        });
      },
      // 只有图片参与拖拽排序，每个child必须有key
      children: List.generate(_imageList.length, (index) {
        return _buildImageItem(index, key: ValueKey(_imageList[index].path));
      }),
    );
  }

  // 当前选中的可见类型标签
  String get _visibleLabel {
    return _visibleOptions.firstWhere(
      (o) => o['value'] == _visibleType,
    )['label'];
  }

  // 跳转联系人选择页
  void _selectVisibleUsers() async {
    final result = await Navigator.pushNamed(
      context,
      RoutePath.contactSelect,
      arguments: {
        'multiSelect': true,
        'selectedIds': _visibleUserIds,
      },
    );
    if (result != null && result is List<String>) {
      setState(() {
        _visibleUserIds = result;
      });
    }
  }

  // 移除已选联系人
  void _removeVisibleUser(String userId) {
    setState(() {
      _visibleUserIds.remove(userId);
    });
  }

  // 构建可见类型选择行
  Widget _buildVisibleTypeRow() {
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        showMyBottomSheet(
          context,
          _visibleOptions.map((option) {
            return SheetItem(option['label'], () {
              setState(() {
                _visibleType = option['value'];
              });
              Navigator.pop(context);
            });
          }).toList(),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.w),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color.fromRGBO(237, 237, 237, 1),
              width: 0.5,
            ),
            bottom: BorderSide(
              color: Color.fromRGBO(237, 237, 237, 1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          spacing: 10.w,
          children: [
            Icon(MyIcon.personCard, size: 20.sp),
            Text('谁可以看', style: TextStyle(fontSize: 16.sp)),
            const Spacer(),
            Text(
              _visibleLabel,
              style: TextStyle(
                fontSize: 14.sp,
                color: Color.fromRGBO(167, 167, 167, 1),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Color.fromRGBO(199, 199, 204, 1),
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  // 构建已选联系人区域
  Widget _buildVisibleContactsSection() {
    final contacts = _visibleContacts;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(237, 237, 237, 1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.w,
        children: [
          // 已选联系人列表
          if (contacts.isNotEmpty)
            Wrap(
              spacing: 8.w,
              runSpacing: 8.w,
              children: List.generate(contacts.length, (index) {
                final contact = contacts[index];
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(242, 242, 242, 1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6.w,
                    children: [
                      ContactAvatar(
                        contactId: contact.contactId,
                        size: 22,
                        shape: .rectangle,
                      ),
                      Text(
                        contact.contactName,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      GestureDetector(
                        onTap: () => _removeVisibleUser(contact.contactId),
                        child: Icon(
                          Icons.close,
                          size: 14.w,
                          color: Color.fromRGBO(167, 167, 167, 1),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          // 选择联系人入口
          GestureDetector(
            onTap: _selectVisibleUsers,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
              decoration: BoxDecoration(
                color: Color.fromRGBO(242, 242, 242, 1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4.w,
                children: [
                  Icon(
                    Icons.add,
                    size: 16.w,
                    color: Color.fromRGBO(167, 167, 167, 1),
                  ),
                  Text(
                    contacts.isEmpty ? '选择联系人' : '继续添加',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color.fromRGBO(167, 167, 167, 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 选项配置区域
  Widget _buildConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVisibleTypeRow(),
        // 可见类型为2(部分可见)或3(不给谁看)时显示联系人选择
        if (_visibleType == 2 || _visibleType == 3)
          _buildVisibleContactsSection(),
      ],
    );
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

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
