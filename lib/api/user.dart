// 图形验证码接口
import 'package:zchat/api/request.dart';
import 'package:zchat/model/user.dart';

// 获取图形验证码
Future<CaptchaRes> getCaptchaApi() async {
  return CaptchaRes.fromJson((await request.get('/user/captcha')));
}

// 登录接口
Future<LoginRes> loginApi(LoginReq data) async {
  return LoginRes.fromJson(
    (await request.post('/user/login', data: data.toJson())),
  );
}

// 注册接口
Future<void> registerApi(RegisterReq data) async {
  await request.post('/user/register', data: data.toJson());
}
