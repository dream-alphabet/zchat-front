import 'package:zchat/api/request.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/group.dart';

// 创建群聊
Future<void> createGroupApi(CreateGroupReq data) async {
  await request.post(Api.createGroup, data: data.toJson());
}