import 'package:dio/dio.dart';

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
  MultipartFile? file;
  String? data;

  SendMsgReq({
    required this.contactId,
    required this.contactType,
    required this.messageType,
    required this.messageContent,
    this.file,
    this.data
  });

  factory SendMsgReq.fromJson(Map<String, dynamic> json) => SendMsgReq(
    contactId: json["contactId"],
    contactType: json["contactType"],
    messageType: json["messageType"],
    messageContent: json["messageContent"],
    file: json["file"],
    data: json['data']
  );

  Map<String, dynamic> toJson() {
    final map = {
      "contactId": contactId,
      "contactType": contactType,
      "messageType": messageType,
      "messageContent": messageContent,
      'data': data
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
  int? maxMessageId;

  GetMsgListReq({
    required this.page,
    required this.pageSize,
    required this.contactId,
    required this.maxMessageId,
  });

  Map<String, dynamic> toMap() => {
    "page": page,
    "pageSize": pageSize,
    "contactId": contactId,
    "maxMessageId": maxMessageId,
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
  String contactName;
  int contactType;
  int? fileId;
  String? fileName;
  int? fileType;
  int? fileSize;
  int status;
  String? data;

  ChatMessageRes({
    required this.messageId,
    required this.sessionId,
    required this.messageType,
    required this.messageContent,
    required this.sendUserId,
    required this.sendUserNickname,
    required this.sendTime,
    required this.contactId,
    required this.contactName,
    required this.contactType,
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.status,
    required this.data
  });

  factory ChatMessageRes.fromJson(Map<String, dynamic> json) => ChatMessageRes(
    messageId: json["messageId"] ?? -1,
    sessionId: json["sessionId"],
    messageType: json["messageType"],
    messageContent: json["messageContent"],
    sendUserId: json["sendUserId"],
    sendUserNickname: json["sendUserNickname"],
    sendTime: json["sendTime"],
    contactId: json["contactId"],
    contactName: json['contactName'] ?? '',
    contactType: json["contactType"],
    fileId: json["fileId"],
    fileName: json["fileName"],
    fileType: json["fileType"],
    fileSize: json["fileSize"],
    status: json["status"],
    data: json['data']
  );

  @override
  String toString() {
    return 'ChatMessageRes{'
        'messageId: $messageId, '
        'sessionId: $sessionId, '
        'messageType: $messageType, '
        'messageContent: $messageContent, '
        'sendUserId: $sendUserId, '
        'sendUserNickname: $sendUserNickname, '
        'sendTime: $sendTime, '
        'contactId: $contactId, '
        'contactName: $contactName, '
        'contactType: $contactType, '
        'fileId: $fileId, '
        'fileName: $fileName, '
        'fileType: $fileType, '
        'fileSize: $fileSize, '
        'status: $status, '
        'data: $data'
        '}';
  }
}
