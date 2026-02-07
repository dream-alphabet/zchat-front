// 全局常量类
class GlobalConstants {
  // 请求基础地址
  static const String baseUrl = 'http://192.168.10.3:8080';
  // 超时时间
  static const int timeout = 5;
  // 业务状态
  // 成功状态
  static const int successCode = 200;
}

// api请求路径常量
class Api {
  static const String getCaptcha = '/user/captcha';
  static const String login = '/user/login';
  static const String register = '/user/register';
  static const String getUserInfo = '/user/userInfo';
}