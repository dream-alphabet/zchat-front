import 'package:flutter/material.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';

// 聊天消息页面
class ChatMessagePage extends StatefulWidget {
  const ChatMessagePage({super.key});

  @override
  State<ChatMessagePage> createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  // 联系人id(用户/群聊)
  String _contactId = '';
  // 联系人类型
  int _contactType = UserContactTypeEnum.user;
  // 联系人信息
  ContactInfoRes? _contactInfo;

  @override
  void initState() {
    super.initState();
    // 接收联系人id和联系人类型参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        _contactType = params['contactType'];
        _getContactInfo();
      }
    });
  }

  // 获取联系人信息
  Future<void> _getContactInfo() async {
    final contactInfo = await getContactInfoApi(_contactId);
    // 结果为空
    if (contactInfo == null) {
      ToastUtils.showGlobalToast(msg: '没有查询到该联系人信息');
      Navigator.pop(context);
      return;
    }
    _contactInfo = contactInfo;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('聊天消息页面'))),
      body: Center(
        child: Column(
          children: [
            Text('联系人id: $_contactId'),
            Text('联系人类型: $_contactType'),
            Text('联系人名称: ${_contactInfo?.contactName}'),
          ],
        ),
      ),
    );
  }
}
