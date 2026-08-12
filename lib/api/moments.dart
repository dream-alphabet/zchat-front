import 'package:dio/dio.dart';
import 'package:zchat/api/request.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/common.dart';
import 'package:zchat/model/moments.dart';

// 发布朋友圈动态
Future<void> publishMomentsApi({
  required String content,
  required List<MultipartFile> files,
  required int visibleType,
  String? visibleUsers,
}) async {
  final formData = FormData();
  if (content.isNotEmpty) {
    formData.fields.add(MapEntry('content', content));
  }
  formData.fields.add(MapEntry('visibleType', visibleType.toString()));
  if (visibleUsers != null && visibleUsers.isNotEmpty) {
    formData.fields.add(MapEntry('visibleUsers', visibleUsers));
  }
  for (final file in files) {
    formData.files.add(MapEntry('files', file));
  }
  await request.upload(Api.publishMoments, formData);
}

// 获取朋友圈时间线
Future<PageRes> getTimelineApi({required int page, int pageSize = 10}) async {
  final res = await request.get(
    Api.getMomentsTimeline,
    params: {'page': page, 'pageSize': pageSize},
  );
  final pageRes = PageRes.fromJson(res);
  return PageRes(
    pages: pageRes.pages,
    total: pageRes.total,
    list: pageRes.list.map((e) => MomentsPostItem.fromJson(e)).toList(),
  );
}

// 点赞/取消点赞
Future<void> toggleLikeApi(int postId) async {
  await request.post('${Api.moments}/$postId/like');
}

// 添加评论
Future<MomentsCommentItem> addCommentApi({
  required int postId,
  required String content,
  int? parentId,
  String? replyToUserId,
}) async {
  final res = await request.post(
    '${Api.moments}/$postId/comment',
    data: {
      'content': content,
      if (parentId != null) 'parentId': parentId,
      if (replyToUserId != null) 'replyToUserId': replyToUserId,
    },
  );
  return MomentsCommentItem.fromJson(res);
}

// 删除评论
Future<void> deleteCommentApi(int commentId) async {
  await request.get('${Api.moments}/comment/$commentId/delete');
}
