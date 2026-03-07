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

// 获取消息列表请求参数
class GetMsgListReq {
  int page;
  int pageSize;
  String contactId;

  GetMsgListReq({
    required this.page,
    required this.pageSize,
    required this.contactId,
  });

  Map<String, dynamic> toMap() => {
    "page": page,
    "pageSize": pageSize,
    "contactId": contactId,
  };
}

// 消息响应结果
class ChatMessageRes {
  int messageId;
  String sessionId;
  int messageType;
  String messageContent;
  String? sendUserId;
  String? sendUserNickname;
  int sendTime;
  String contactId;
  int contactType;
  String? fileId;
  String? fileName;
  int status;

  ChatMessageRes({
    required this.messageId,
    required this.sessionId,
    required this.messageType,
    required this.messageContent,
    required this.sendUserId,
    required this.sendUserNickname,
    required this.sendTime,
    required this.contactId,
    required this.contactType,
    required this.fileId,
    required this.fileName,
    required this.status,
  });

  factory ChatMessageRes.fromJson(Map<String, dynamic> json) => ChatMessageRes(
    messageId: json["messageId"],
    sessionId: json["sessionId"],
    messageType: json["messageType"],
    messageContent: json["messageContent"],
    sendUserId: json["sendUserId"],
    sendUserNickname: json["sendUserNickname"],
    sendTime: json["sendTime"],
    contactId: json["contactId"],
    contactType: json["contactType"],
    fileId: json["fileId"],
    fileName: json["fileName"],
    status: json["status"],
  );
}
