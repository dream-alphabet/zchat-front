// 创建群聊请求参数
class CreateGroupReq {
  String groupName;
  String groupNotice;

  CreateGroupReq({
    required this.groupName,
    required this.groupNotice,
  });

  factory CreateGroupReq.fromJson(Map<String, dynamic> json) => CreateGroupReq(
    groupName: json["groupName"],
    groupNotice: json["groupNotice"],
  );

  Map<String, dynamic> toJson() => {
    "groupName": groupName,
    "groupNotice": groupNotice,
  };
}