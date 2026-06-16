// 图形验证码响应结果
import 'package:dio/dio.dart';

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

// 用户信息
class UserInfo {
  String userId;
  String email;
  String nickname;
  String password;
  int joinType;
  int? gender;
  String? personDesc;
  int createTime;
  int? lastLoginTime;
  int? lastOffTime;

  UserInfo({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.password,
    required this.joinType,
    required this.gender,
    required this.personDesc,
    required this.createTime,
    required this.lastLoginTime,
    required this.lastOffTime,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    userId: json["userId"],
    email: json["email"],
    nickname: json["nickname"],
    password: json["password"],
    joinType: json["joinType"],
    gender: json["gender"],
    personDesc: json["personDesc"],
    createTime: json["createTime"],
    lastLoginTime: json["lastLoginTime"],
    lastOffTime: json["lastOffTime"],
  );

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "email": email,
    "nickname": nickname,
    "password": password,
    "joinType": joinType,
    "gender": gender,
    "personDesc": personDesc,
    "createTime": createTime,
    "lastLoginTime": lastLoginTime,
    "lastOffTime": lastOffTime,
  };
}

// 更新用户头像请求参数
class UpdateAvatarReq {
  final MultipartFile avatar;

  UpdateAvatarReq({required this.avatar});

  Map<String, dynamic> toJson() => {'avatar': avatar};
}
