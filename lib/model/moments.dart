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

// 点赞用户
class MomentsLikeItem {
  String userId;
  String nickname;

  MomentsLikeItem({required this.userId, required this.nickname});

  factory MomentsLikeItem.fromJson(Map<String, dynamic> json) {
    return MomentsLikeItem(
      userId: json['userId'],
      nickname: json['nickname'] ?? '',
    );
  }
}

// 评论
class MomentsCommentItem {
  int id;
  int postId;
  String userId;
  String nickname;
  int? parentId;
  String? replyToUserId;
  String? replyToNickname;
  String content;
  String createTime;

  MomentsCommentItem({
    required this.id,
    required this.postId,
    required this.userId,
    required this.nickname,
    this.parentId,
    this.replyToUserId,
    this.replyToNickname,
    required this.content,
    required this.createTime,
  });

  factory MomentsCommentItem.fromJson(Map<String, dynamic> json) {
    return MomentsCommentItem(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      nickname: json['nickname'] ?? '',
      parentId: json['parentId'],
      replyToUserId: json['replyToUserId'],
      replyToNickname: json['replyToNickname'],
      content: json['content'] ?? '',
      createTime: json['createTime'] ?? '',
    );
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
  bool liked;
  List<MomentsMediaItem> mediaList;
  List<MomentsLikeItem> likeList;
  List<MomentsCommentItem> commentList;

  MomentsPostItem({
    required this.postId,
    required this.userId,
    required this.nickname,
    this.content,
    required this.visibleType,
    required this.createTime,
    required this.liked,
    required this.mediaList,
    required this.likeList,
    required this.commentList,
  });

  factory MomentsPostItem.fromJson(Map<String, dynamic> json) {
    return MomentsPostItem(
      postId: json['postId'],
      userId: json['userId'],
      nickname: json['nickname'] ?? '',
      content: json['content'],
      visibleType: json['visibleType'] ?? 0,
      createTime: json['createTime'] ?? '',
      liked: json['liked'] ?? false,
      mediaList: (json['mediaList'] as List<dynamic>?)
              ?.map((e) => MomentsMediaItem.fromJson(e))
              .toList() ??
          [],
      likeList: (json['likeList'] as List<dynamic>?)
              ?.map((e) => MomentsLikeItem.fromJson(e))
              .toList() ??
          [],
      commentList: (json['commentList'] as List<dynamic>?)
              ?.map((e) => MomentsCommentItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
