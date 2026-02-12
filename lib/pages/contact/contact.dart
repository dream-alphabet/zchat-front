import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/widgets/contact_avatar.dart';
import 'package:zchat/widgets/ink_click.dart';
import 'package:zchat/widgets/page_header.dart';

// 联系人
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  // 功能列表数据
  final _functionList = [
    ListItemData(
      leftIcon: MyIcon.newFriend,
      rightName: '新的朋友',
      path: RoutePath.newFriend,
    ),
    ListItemData(
      leftIcon: MyIcon.message,
      rightName: '仅聊天的朋友',
      path: RoutePath.onlyChatFriend,
    ),
    ListItemData(
      leftIcon: MyIcon.groupChat,
      rightName: '群聊',
      path: RoutePath.groupChat,
    ),
  ];
  // 联系人列表数据
  final _contactList = [
    ListItemData(
      userId: '123',
      isFunction: false,
      leftAvatar: 'lib/assets/test/01.png',
      rightName: '用户A',
      path: RoutePath.contactInfo,
    ),
    ListItemData(
      userId: '456',
      isFunction: false,
      leftAvatar: 'lib/assets/test/01.png',
      rightName: '用户B',
      path: RoutePath.contactInfo,
    ),
  ];

  // 构建空白内容
  Widget _buildBlank() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 30.w,
      children: [
        SizedBox(height: 50.w),
        Image.asset(
          'lib/assets/images/chat-blank.png',
          width: 113.w,
          height: 107.w,
        ),
        Text(
          '快去寻找好友吧!',
          style: TextStyle(fontSize: 16.sp, color: Colors.black),
        ),
      ],
    );
  }

  // 列表项
  Widget _buildListItem(ListItemData data, bool showBorder) {
    return InkClick(
      backgroundColor: Colors.white,
      onTap: () {
        Navigator.pushNamed(
          context,
          data.path,
          arguments: {'contactId': data.userId},
        );
      },
      child: Container(
        padding: EdgeInsets.only(left: 15.w),
        child: Row(
          spacing: 15.w,
          children: [
            // 如果是功能列表项显示图标，联系人就显示头像
            data.isFunction
                ? Container(
                    width: 40.w,
                    height: 40.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.w),
                      color: Color.fromRGBO(20, 134, 237, 1),
                    ),
                    child: Icon(data.leftIcon, color: Colors.white, size: 26.w),
                  )
                : ContactAvatar(imageUrl: data.leftAvatar ?? ''),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: showBorder
                        ? BorderSide(
                            color: Color.fromRGBO(232, 232, 232, 1),
                            width: 1.w,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Container(
                  height: 40.w,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.rightName,
                    style: TextStyle(color: Colors.black, fontSize: 15.w),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建功能列表
  Widget _buildFunctionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        _functionList.length,
        (index) => _buildListItem(
          _functionList[index],
          index < _functionList.length - 1,
        ),
      ),
    );
  }

  // 联系人列表
  Widget _buildContactList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        _contactList.length,
        (index) => _buildListItem(
          _contactList[index],
          index < _contactList.length - 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(237, 237, 237, 1),
      body: ListView(
        children: [
          PageHeader(title: '通讯录'),
          _buildFunctionList(),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(
              horizontal: 15.w,
              vertical: 10.w,
            ),
            child: Text(
              '联系人',
              style: TextStyle(
                color: Color.fromRGBO(97, 97, 97, 1),
                fontSize: 14.sp,
              ),
            ),
          ),
          _contactList.isEmpty ? _buildBlank() : _buildContactList(),
        ],
      ),
    );
  }
}

// 列表项数据
class ListItemData {
  final String rightName;
  final IconData? leftIcon;
  final String? leftAvatar;
  final String? userId;
  final String path;
  final bool isFunction;

  ListItemData({
    this.leftIcon,
    this.leftAvatar,
    this.userId,
    required this.rightName,
    required this.path,
    this.isFunction = true,
  });
}
