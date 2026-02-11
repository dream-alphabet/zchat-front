// 查询用户/群组是否存在
import 'package:zchat/api/request.dart';
import 'package:zchat/common/constants.dart';

Future<bool> searchContactExistApi(String keyword) async {
  return (await request.get(Api.searchContactExist, params: {'keyword': keyword}));
}
