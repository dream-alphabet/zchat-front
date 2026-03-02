// 消息类型枚举
enum MessageTypeEnum {
  // 文本消息
  text(type: 0, messageContent: '');

  const MessageTypeEnum({required this.type, required this.messageContent});

  final int type;
  final String messageContent;
}
