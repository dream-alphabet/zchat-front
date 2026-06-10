// 联系人信息响应
class ContactInfoRes {
  String contactId;
  String contactName;
  int contactStatus;
  int contactType;
  int? memberCount;
  String sessionId;

  ContactInfoRes({
    required this.contactId,
    required this.contactName,
    required this.contactStatus,
    required this.contactType,
    required this.memberCount,
    required this.sessionId
  });

  factory ContactInfoRes.fromJson(Map<String, dynamic> json) => ContactInfoRes(
    contactId: json["contactId"],
    contactName: json["contactName"],
    contactStatus: json["contactStatus"],
    contactType: json["contactType"],
    memberCount: json['memberCount'],
    sessionId: json['sessionId']
  );

  Map<String, dynamic> toJson() => {
    "contactId": contactId,
    "contactName": contactName,
    "contactStatus": contactStatus,
    "contactType": contactType,
    'sessionId': sessionId
  };
}

// 发送添加好友申请请求参数
class SendApplyReq {
  String contactId;
  String applyInfo;

  SendApplyReq({required this.contactId, required this.applyInfo});

  Map<String, dynamic> toJson() => {
    "contactId": contactId,
    "applyInfo": applyInfo,
  };
}

// 联系人申请响应
class ContactApplyRes {
  int applyId;
  String applyUserId;
  String receiveUserId;
  int contactType;
  String contactId;
  String contactName;
  String? groupName;
  int status;
  String applyInfo;
  int applyTime;
  int? handleTime;

  ContactApplyRes({
    required this.applyId,
    required this.applyUserId,
    required this.receiveUserId,
    required this.contactType,
    required this.contactId,
    required this.contactName,
    required this.groupName,
    required this.status,
    required this.applyInfo,
    required this.applyTime,
    required this.handleTime,
  });

  factory ContactApplyRes.fromJson(Map<String, dynamic> json) =>
      ContactApplyRes(
        applyId: json["applyId"],
        applyUserId: json["applyUserId"],
        receiveUserId: json["receiveUserId"],
        contactType: json["contactType"],
        contactId: json["contactId"],
        contactName: json["contactName"],
        groupName: json['groupName'],
        status: json["status"],
        applyInfo: json["applyInfo"],
        applyTime: json["applyTime"],
        handleTime: json["handleTime"],
      );

  Map<String, dynamic> toJson() => {
    "applyId": applyId,
    "applyUserId": applyUserId,
    "receiveUserId": receiveUserId,
    "contactType": contactType,
    "contactId": contactId,
    "contactName": contactName,
    "status": status,
    "applyInfo": applyInfo,
    "applyTime": applyTime,
    "handleTime": handleTime,
  };
}

// 获取申请列表请求参数
class ApplyListReq {
  int page;
  int pageSize;

  ApplyListReq({required this.page, required this.pageSize});

  Map<String, dynamic> toMap() => {"page": page, "pageSize": pageSize};
}

// 处理联系人申请请求参数
class HandleApplyReq {
  int applyId;
  int status;

  HandleApplyReq({required this.applyId, required this.status});

  Map<String, dynamic> toMap() => {"applyId": applyId, "status": status};
}

// 联系人响应对象
class UserContactRes {
  String contactId;
  String contactName;

  UserContactRes({required this.contactId, required this.contactName});

  factory UserContactRes.fromJson(Map<String, dynamic> json) => UserContactRes(
    contactId: json["contactId"],
    contactName: json["contactName"],
  );

  Map<String, dynamic> toJson() => {
    "contactId": contactId,
    "contactName": contactName,
  };
}
