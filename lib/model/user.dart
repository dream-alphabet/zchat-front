// 图形验证码响应结果
class CaptchaRes {
  String captcha;
  String captchaKey;

  CaptchaRes({required this.captcha, required this.captchaKey});

  factory CaptchaRes.fromJson(Map<String, dynamic> json) =>
      CaptchaRes(captcha: json["captcha"], captchaKey: json["captchaKey"]);
}

// 登录接口请求参数
class LoginReq {
  String email;
  String password;
  String captchaKey;
  String userCaptcha;

  LoginReq({
    required this.email,
    required this.password,
    required this.captchaKey,
    required this.userCaptcha,
  });

  Map<String, dynamic> toJson() => {
    "email": email,
    "password": password,
    "captchaKey": captchaKey,
    "userCaptcha": userCaptcha,
  };
}

// 登录接口响应结果
class LoginRes {
  String token;

  LoginRes({required this.token});

  factory LoginRes.fromJson(Map<String, dynamic> json) =>
      LoginRes(token: json["token"]);
}

// 注册接口请求参数
class RegisterReq {
  String nickname;
  String email;
  String password;
  String captchaKey;
  String userCaptcha;

  RegisterReq({
    required this.nickname,
    required this.email,
    required this.password,
    required this.captchaKey,
    required this.userCaptcha,
  });

  Map<String, dynamic> toJson() => {
    "nickname": nickname,
    "email": email,
    "password": password,
    "captchaKey": captchaKey,
    "userCaptcha": userCaptcha,
  };
}
