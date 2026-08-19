// 联系人信息响应
class ContactInfoRes {
  String contactId;
  String contactName;
  int contactStatus;
  int contactType;
  int? memberCount;
  int? groupStatus;
  String sessionId;
  int? disturb;
  int? permission;
  bool? canViewMoments;
  int? gender;
  String? personDesc;

  ContactInfoRes({
    required this.contactId,
    required this.contactName,
    required this.contactStatus,
    required this.contactType,
    required this.memberCount,
    required this.groupStatus,
    required this.sessionId,
    this.disturb,
    this.permission,
    this.canViewMoments,
    this.gender,
    this.personDesc,
  });

  factory ContactInfoRes.fromJson(Map<String, dynamic> json) => ContactInfoRes(
    contactId: json["contactId"],
    contactName: json["contactName"],
    contactStatus: json["contactStatus"],
    contactType: json["contactType"],
    memberCount: json['memberCount'],
    groupStatus: json['groupStatus'],
    sessionId: json['sessionId'],
    disturb: json['disturb'],
    permission: json['permission'],
    canViewMoments: json['canViewMoments'],
    gender: json['gender'],
    personDesc: json['personDesc'],
  );
}

// 发送添加好友申请请求参数
class SendApplyReq {
  String contactId;
  String applyInfo;
  String? applyRemark;
  int? applyPermission;

  SendApplyReq({
    required this.contactId,
    required this.applyInfo,
    this.applyRemark,
    this.applyPermission,
  });

  Map<String, dynamic> toJson() => {
    "contactId": contactId,
    "applyInfo": applyInfo,
    "applyRemark": applyRemark,
    "applyPermission": applyPermission,
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
  String? applyRemark;
  int? applyPermission;
  String? handleRemark;
  int? handlePermission;
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
    this.applyRemark,
    this.applyPermission,
    this.handleRemark,
    this.handlePermission,
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
        applyRemark: json['applyRemark'],
        applyPermission: json['applyPermission'],
        handleRemark: json['handleRemark'],
        handlePermission: json['handlePermission'],
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
    "applyRemark": applyRemark,
    "applyPermission": applyPermission,
    "handleRemark": handleRemark,
    "handlePermission": handlePermission,
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
  String? handleRemark;
  int? handlePermission;

  HandleApplyReq({
    required this.applyId,
    required this.status,
    this.handleRemark,
    this.handlePermission,
  });

  Map<String, dynamic> toMap() => {
    "applyId": applyId,
    "status": status,
    "handleRemark": handleRemark,
    "handlePermission": handlePermission,
  };
}

// 联系人响应对象
class UserContactRes {
  String userId;
  String contactId;
  int contactType;
  int status;
  String? remark;
  String? groupNickname;
  int disturb;
  int permission;
  int createTime;
  int updateTime;
  String originName;

  // 获取contactName: 优先使用备注，备注为空再使用原始名称
  String get contactName {
    if (remark == null || remark!.isEmpty) {
      return originName;
    }
    return remark!;
  }

  UserContactRes({
    required this.userId,
    required this.contactId,
    required this.contactType,
    required this.status,
    this.remark,
    this.groupNickname,
    this.disturb = 0,
    this.permission = 0,
    required this.createTime,
    required this.updateTime,
    required this.originName,
  });

  factory UserContactRes.fromJson(Map<String, dynamic> json) {
    return UserContactRes(
      userId: json['userId'],
      contactId: json['contactId'],
      contactType: json['contactType'],
      status: json['status'],
      remark: json['remark'],
      groupNickname: json['groupNickname'],
      disturb: json['disturb'] ?? 0,
      permission: json['permission'] ?? 0,
      createTime: json['createTime'],
      updateTime: json['updateTime'],
      originName: json['originName'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'contactId': contactId,
    'contactType': contactType,
    'status': status,
    'remark': remark,
    'groupNickname': groupNickname,
    'disturb': disturb,
    'permission': permission,
    'createTime': createTime,
    'updateTime': updateTime,
    'originName': originName,
  };
}

// 搜索联系人请求参数
class SearchContactReq {
  final String keywords;
  final int? contactType;

  SearchContactReq({required this.keywords, this.contactType});

  Map<String, dynamic> toJson() => {
    'keywords': keywords,
    'contactType': contactType,
  };
}

// 更新联系人设置请求参数
class UpdateContactSettingReq {
  String contactId;
  String? remark;
  String? groupNickname;
  int? disturb;
  int? permission;
  int? isTop;

  UpdateContactSettingReq({
    required this.contactId,
    this.remark,
    this.groupNickname,
    this.disturb,
    this.permission,
    this.isTop,
  });

  factory UpdateContactSettingReq.fromJson(Map<String, dynamic> json) {
    return UpdateContactSettingReq(
      contactId: json['contactId'],
      remark: json['remark'],
      groupNickname: json['groupNickname'],
      disturb: json['disturb'],
      permission: json['permission'],
      isTop: json['isTop'],
    );
  }

  Map<String, dynamic> toJson() => {
    'contactId': contactId,
    'remark': remark,
    'groupNickname': groupNickname,
    'disturb': disturb,
    'permission': permission,
    'isTop': isTop,
  };
}
