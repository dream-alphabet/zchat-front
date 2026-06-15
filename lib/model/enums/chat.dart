// 消息类型枚举
enum MessageTypeEnum {
  // 文本消息
  text(type: 0, messageContent: ''),
  // 文件消息
  file(type: 1, messageContent: ''),
  // 视频通话
  videoCall(type: 2, messageContent: '[视频通话]'),
  // 语音通话
  voiceCall(type: 3, messageContent: '[语音通话]'),
  // webrtc信令消息
  rtcSignal(type: 4, messageContent: ''),
  // 系统通知
  systemNotice(type: 5, messageContent: '');

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

// webrtc信令枚举
class RTCSignalEnum {
  // offer
  static const offer = 'offer';
  // answer
  static const answer = 'answer';
  // candidate
  static const candidate = 'candidate';
  // callEnd(挂断)
  static const callEnd = 'callEnd';
}
