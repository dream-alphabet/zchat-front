// 全局常量类
class GlobalConstants {
  // 请求基础地址
  static const baseUrl = 'http://192.168.10.3:8080';
  // 超时时间
  static const timeout = 5;
  // 业务状态
  // 成功状态
  static const successCode = 200;
}

// api请求路径常量
class Api {
  static const getCaptcha = '/user/captcha';
  static const login = '/user/login';
  static const register = '/user/register';
  static const getUserInfo = '/user/userInfo';
}

// 路由路径常量
class RoutePath {
  // 主页面
  static const main = '/';
  // 登录
  static const login = '/login';
  // 注册
  static const register = '/register';
  // 新的朋友(查看好友申请)
  static const newFriend = '/newFriend';
  // 仅聊天的朋友
  static const onlyChatFriend = '/onlyChatFriend';
  // 群聊(查看加入的群聊)
  static const groupChat = '/groupChat';
  // 用户信息
  static const userInfo = '/userInfo';
  // 朋友圈
  static const moments = '/moments';
  // 扫一扫
  static const scan = '/scan';
  // 添加朋友
  static const addFriend = '/addFriend';
  // 发起群聊
  static const createGroup = '/createGroup';
}