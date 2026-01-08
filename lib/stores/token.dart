import 'package:shared_preferences/shared_preferences.dart';

// token持久化存储的key
const _tokenKey = 'token';

// token管理器
class TokenManager {
  // 获取持久化对象的实例
  Future<SharedPreferences> _getInstance() {
    return SharedPreferences.getInstance();
  }

  // 持久化实例对象
  SharedPreferences? _instance;

  // 初始化token
  Future<void> init() async {
    _instance = await _getInstance();
  }

  // 设置token
  void setToken(String token) async {
    _instance?.setString(_tokenKey, token);
  }

  // 获取token
  String getToken() {
    return _instance?.getString(_tokenKey) ?? '';
  }

  // 删除token
  void removeToken() {
    _instance?.remove(_tokenKey);
  }
}

// 只有一个实例
final tokenManager = TokenManager();
