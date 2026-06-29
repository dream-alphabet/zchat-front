import 'package:dio/dio.dart';

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
