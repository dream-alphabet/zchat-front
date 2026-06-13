// 服务器消息实体
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/contact.dart';

// 新增联系人消息
class AddContactMsg {
  int contactType;
  UserContactRes contact;
  ChatSessionRes session;

  AddContactMsg({
    required this.contactType,
    required this.contact,
    required this.session,
  });

  factory AddContactMsg.fromJson(Map<String, dynamic> json) => AddContactMsg(
    contactType: json['contactType'],
    contact: UserContactRes.fromJson(json['contact']),
    session: ChatSessionRes.fromJson(json['session']),
  );
}
