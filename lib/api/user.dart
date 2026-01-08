// 图形验证码接口
import 'package:zchat/api/request.dart';
import 'package:zchat/model/user.dart';

// 获取图形验证码
Future<CaptchaRes> getCaptchaApi() async {
  return CaptchaRes.fromJson((await request.get('/user/captcha')));
}