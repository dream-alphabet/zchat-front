import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/ink_click.dart';

// 个人卡片组件
class PersonCard extends StatelessWidget {
  final UserContactRes contact;

  const PersonCard({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250.w,
      padding: .all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(5.r),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 10.w,
        children: [
          Row(
            spacing: 10.w,
            children: [
              ContactAvatar(contactId: contact.contactId, shape: .rectangle),
              Expanded(
                child: Text(
                  contact.contactName,
                  style: TextStyle(fontSize: 16.sp, color: Colors.black),
                  overflow: .ellipsis,
                ),
              ),
            ],
          ),
          Text(
            '个人名片',
            style: TextStyle(
              fontSize: 14.sp,
              color: Color.fromRGBO(110, 110, 108, 1),
            ),
          ),
        ],
      ),
    );
  }
}

// 弹出是否确认发送个人卡片
Future<bool?> showSendConfirmModal(
  BuildContext context,
  UserContactRes receiver,
  UserContactRes contact,
) {
  return showModalBottomSheet<bool>(
    backgroundColor: Color.fromRGBO(237, 237, 237, 1),
    context: context,
    builder: (context) {
      return SafeArea(
        child: ClipRRect(
          borderRadius: .only(
            topLeft: .circular(5.r),
            topRight: .circular(5.r),
          ),
          clipBehavior: .antiAlias,
          child: Container(
            width: double.infinity,
            padding: .only(left: 15.w, right: 15.w, top: 15.w, bottom: 40.w),
            child: Column(
              mainAxisSize: .min,
              spacing: 10.w,
              children: [
                Row(
                  spacing: 10.w,
                  children: [
                    Text('发送给:'),
                    ContactAvatar(contactId: receiver.contactId),
                    Text(receiver.contactName),
                  ],
                ),
                // 个人名片
                PersonCard(contact: contact),
                Row(
                  mainAxisAlignment: .center,
                  spacing: 15.w,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context, false);
                      },
                      child: Container(
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(247, 247, 247, 1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.w),
                        alignment: Alignment.center,
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context, true);
                      },
                      child: Container(
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(20, 134, 237, 1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.w),
                        alignment: Alignment.center,
                        child: Text(
                          '发送',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// 弹出底部列表选择
void showMyBottomSheet(BuildContext context, List<SheetItem> items) {
  // 显示BottomSheet
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
