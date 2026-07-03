import 'package:dio/dio.dart';
import 'package:zchat/model/contact.dart';

// 创建群聊请求参数
class CreateGroupReq {
  String groupName;
  String groupNotice;
  MultipartFile? cover;

  CreateGroupReq({
    required this.groupName,
    required this.groupNotice,
    required this.cover,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      "groupName": groupName,
      "groupNotice": groupNotice,
    };
    if (cover != null) {
      map['cover'] = cover ?? '';
    }
    return map;
  }
}

// 群聊实体类
class Group {
  String groupid;
  String groupName;
  String groupOwnerid;
  String groupNotice;
  int joinType;
  int status;
  int createTime;

  Group({
    required this.groupid,
    required this.groupName,
    required this.groupOwnerid,
    required this.groupNotice,
    required this.joinType,
    required this.status,
    required this.createTime,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupid: json['groupId'],
      groupName: json['groupName'],
      groupOwnerid: json['groupOwnerId'],
      groupNotice: json['groupNotice'],
      joinType: json['joinType'],
      status: json['status'],
      createTime: json['createTime'],
    );
  }

  Map<String, dynamic> toJson() => {
    'groupId': groupid,
    'groupName': groupName,
    'groupOwnerId': groupOwnerid,
    'groupNotice': groupNotice,
    'joinType': joinType,
    'status': status,
    'createTime': createTime,
  };
}

// 群聊设置信息响应结果
class GetGroupSettingsRes {
  List<UserContactRes> members;
  Group group;

  GetGroupSettingsRes({required this.members, required this.group});

  factory GetGroupSettingsRes.fromJson(Map<String, dynamic> json) {
    return GetGroupSettingsRes(
      members: (json['members'] as List)
          .map((e) => UserContactRes.fromJson(e))
          .toList(),
      group: Group.fromJson(json['group'])
    );
  }

  Map<String, dynamic> toJson() => {
    'members': members.map((e) => e.toJson()).toList(),
    'group': group.toJson()
  };
}
