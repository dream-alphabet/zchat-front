import 'package:dio/dio.dart';

// 会话响应结果
class ChatSessionRes {
  String sessionId;
  String contactId;
  int contactType;
  String? remark;
  String originName;
  String? lastMessage;
  int? lastReceiveTime;
  int disturb;

  // 获取contactName: 优先使用备注，备注为空再使用原始名称
  String get contactName => remark ?? originName;

  ChatSessionRes({
    required this.sessionId,
    required this.contactId,
    required this.contactType,
    this.remark,
    required this.originName,
    required this.lastMessage,
    required this.lastReceiveTime,
    this.disturb = 0,
  });

  factory ChatSessionRes.fromJson(Map<String, dynamic> json) {
    return ChatSessionRes(
      sessionId: json['sessionId'],
      contactId: json['contactId'],
      contactType: json['contactType'],
      remark: json['remark'],
      originName: json['originName'],
      lastMessage: json['lastMessage'],
      lastReceiveTime: json['lastReceiveTime'],
      disturb: json['disturb'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'contactId': contactId,
    'contactType': contactType,
    'remark': remark,
    'originName': originName,
    'lastMessage': lastMessage,
    'lastReceiveTime': lastReceiveTime,
    'disturb': disturb,
  };

  // 新增 copyWith 方法
  ChatSessionRes copyWith({
    String? sessionId,
    String? contactId,
    int? contactType,
    String? remark,
    String? originName,
    String? lastMessage,
    int? lastReceiveTime,
    int? disturb,
  }) {
    return ChatSessionRes(
      sessionId: sessionId ?? this.sessionId,
      contactId: contactId ?? this.contactId,
      contactType: contactType ?? this.contactType,
      remark: remark ?? this.remark,
      originName: originName ?? this.originName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastReceiveTime: lastReceiveTime ?? this.lastReceiveTime,
      disturb: disturb ?? this.disturb,
    );
  }
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
    this.data,
  });

  Map<String, dynamic> toJson() {
    final map = {
      "contactId": contactId,
      "contactType": contactType,
      "messageType": messageType,
      "messageContent": messageContent,
      'data': data,
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

// 搜索聊天记录请求参数
class SearchMsgReq {
  String keyword;
  String contactId;
  int page;
  int pageSize;

  SearchMsgReq({
    required this.keyword,
    required this.contactId,
    required this.page,
    required this.pageSize,
  });

  Map<String, dynamic> toMap() => {
    "keyword": keyword,
    "contactId": contactId,
    "page": page,
    "pageSize": pageSize,
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
    required this.data,
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
    data: json['data'],
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

// 转发消息请求参数
class ShareMsgReq {
  int messageId;
  String contactId;
  int contactType;

  ShareMsgReq({
    required this.messageId,
    required this.contactId,
    required this.contactType,
  });

  factory ShareMsgReq.fromJson(Map<String, dynamic> json) {
    return ShareMsgReq(
      messageId: json['messageId'],
      contactId: json['contactId'],
      contactType: json['contactType'],
    );
  }

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'contactId': contactId,
    'contactType': contactType,
  };
}
