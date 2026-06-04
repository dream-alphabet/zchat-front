import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class MessageController extends GetxController {
  // 持久化实例
  final _storage = GetStorage();

  // 未读消息数量map(sessionId->数量)
  late final RxMap<String, int> unreadCount;

  @override
  void onInit() {
    super.onInit();
    // 读取本地存储的未读消息数量
    final saved = _storage.read('unreadCount');
    if (saved != null && saved is Map<String, dynamic>) {
      // 将 Map<String, dynamic> 转换为 Map<String, int>
      final converted = saved.map((key, value) {
        // 确保 value 是 int，如果不是则尝试转换或设为 0
        final intValue = (value as int?) ?? 0;
        return MapEntry(key, intValue);
      });
      unreadCount = RxMap<String, int>.from(converted);
    } else {
      unreadCount = RxMap<String, int>();
    }
    // 监听变化并持久化
    ever(unreadCount, (_) {
      _storage.write('unreadCount', unreadCount);
    });
  }

  // 新增指定会话的未读消息数量
  void addSessionUnreadCount(String sessionId) {
    unreadCount[sessionId] = (unreadCount[sessionId] ?? 0) + 1;
  }

  // 清零指定会话未读消息数量
  void clearSessionUnreadCount(String sessionId) {
    unreadCount[sessionId] = 0;
  }
}

// 未读消息类型(默认为聊天消息，这里没写)
class UnreadType {
  // 联系人申请
  static final contactApply = 'contactApply';
}
