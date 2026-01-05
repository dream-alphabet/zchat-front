// 会话列表项
class ChatSession {
  final String sessionId;
  final String contactName;
  final String contactId;
  final String lastMessage;
  final int lastReceiveTime;
  final int noReadCount;

  ChatSession({
    required this.sessionId,
    required this.contactName,
    required this.contactId,
    required this.lastMessage,
    required this.lastReceiveTime,
    required this.noReadCount
  });
}