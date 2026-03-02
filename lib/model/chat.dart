import 'dart:io';

// 会话响应结果
class ChatSessionRes {
  String sessionId;
  String contactId;
  int contactType;
  String contactName;
  String? lastMessage;
  int? lastReceiveTime;

  ChatSessionRes({
    required this.sessionId,
    required this.contactId,
    required this.contactType,
    required this.contactName,
    required this.lastMessage,
    required this.lastReceiveTime,
  });

  factory ChatSessionRes.fromJson(Map<String, dynamic> json) => ChatSessionRes(
    sessionId: json["sessionId"],
    contactId: json["contactId"],
    contactType: json["contactType"],
    contactName: json["contactName"],
    lastMessage: json["lastMessage"],
    lastReceiveTime: json["lastReceiveTime"],
  );
}

// 发送消息请求参数
class SendMsgReq {
  String contactId;
  int contactType;
  int messageType;
  String messageContent;
  File? file;

  SendMsgReq({
    required this.contactId,
    required this.contactType,
    required this.messageType,
    required this.messageContent,
    this.file,
  });

  factory SendMsgReq.fromJson(Map<String, dynamic> json) => SendMsgReq(
    contactId: json["contactId"],
    contactType: json["contactType"],
    messageType: json["messageType"],
    messageContent: json["messageContent"],
    file: json["file"],
  );

  Map<String, dynamic> toJson() {
    final map = {
      "contactId": contactId,
      "contactType": contactType,
      "messageType": messageType,
      "messageContent": messageContent,
    };
    if (file != null) {
      map['file'] = file ?? '';
    }
    return map;
  }
}
