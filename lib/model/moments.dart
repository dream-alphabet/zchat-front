import 'package:zchat/common/constants.dart';

// 朋友圈动态媒体
class MomentsMediaItem {
  int mediaType; // 1-图片, 2-视频
  int fileId;
  String fileName;
  int sortOrder;

  MomentsMediaItem({
    required this.mediaType,
    required this.fileId,
    required this.fileName,
    required this.sortOrder,
  });

  factory MomentsMediaItem.fromJson(Map<String, dynamic> json) {
    return MomentsMediaItem(
      mediaType: json['mediaType'],
      fileId: json['fileId'],
      fileName: json['fileName'] ?? '',
      sortOrder: json['sortOrder'],
    );
  }

  String get fileUrl {
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '';
    return '${GlobalConstants.fileUrl}/moments/$fileId$ext';
  }
}

// 朋友圈动态
class MomentsPostItem {
  int postId;
  String userId;
  String nickname;
  String? content;
  int visibleType;
  String createTime;
  List<MomentsMediaItem> mediaList;

  MomentsPostItem({
    required this.postId,
    required this.userId,
    required this.nickname,
    this.content,
    required this.visibleType,
    required this.createTime,
    required this.mediaList,
  });

  factory MomentsPostItem.fromJson(Map<String, dynamic> json) {
    return MomentsPostItem(
      postId: json['postId'],
      userId: json['userId'],
      nickname: json['nickname'] ?? '',
      content: json['content'],
      visibleType: json['visibleType'] ?? 0,
      createTime: json['createTime'] ?? '',
      mediaList: (json['mediaList'] as List<dynamic>?)
              ?.map((e) => MomentsMediaItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
