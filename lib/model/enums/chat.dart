// 消息类型枚举
enum MessageTypeEnum {
  // 文本消息
  text(type: 0, messageContent: ''),
  // 文件消息
  file(type: 1, messageContent: '');

  const MessageTypeEnum({required this.type, required this.messageContent});

  final int type;
  final String messageContent;
}

// 文件类型枚举
enum FileTypeEnum {
  // 图片
  image(type: 0, messageContent: '[图片]'),
  // 视频
  video(type: 1, messageContent: '[视频]'),
  // 其他文件
  file(type: 2, messageContent: '[文件]');

  const FileTypeEnum({required this.type, required this.messageContent});

  final int type;
  final String messageContent;
}
