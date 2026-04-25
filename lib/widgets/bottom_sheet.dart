import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/widgets/ink_click.dart';

// 显示底部弹窗
void showMyBottomSheet(BuildContext context, List<SheetItem> items) {
  // 显示ActionSheet
  showModalBottomSheet(
    backgroundColor: Color.fromRGBO(237, 237, 237, 1),
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: ClipRRect(
          borderRadius: .only(
            topLeft: .circular(10.r),
            topRight: .circular(10.r),
          ),
          clipBehavior: .antiAlias,
          child: Column(
            mainAxisSize: .min,
            children: [
              ...List.generate(
                items.length,
                (index) => _buildSheetItem(items[index]),
              ),
              SizedBox(height: 10.w),
              _buildSheetItem(
                SheetItem('取消', () {
                  Navigator.pop(context);
                }),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// 构建弹窗列表项
Widget _buildSheetItem(SheetItem item) {
  return InkClick(
    onTap: item.onTap,
    backgroundColor: Colors.white,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 15.w),
      alignment: .center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1.w,
            color: Color.fromRGBO(237, 237, 237, 1),
          ),
        ),
      ),
      child: Text(
        item.text,
        style: TextStyle(color: Colors.black, fontSize: 16.sp),
      ),
    ),
  );
}

class SheetItem {
  final String text;
  final GestureTapCallback onTap;

  SheetItem(this.text, this.onTap);
}
