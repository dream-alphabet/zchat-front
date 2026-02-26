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
