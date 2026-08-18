import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/stores/session.dart';

class MessageController extends GetxController {
  // 持久化实例
  final _storage = GetStorage();

  // 未读消息数量map(聊天消息，sessionId->数量)
  late final RxMap<String, int> unreadCount;
  // 未读消息数量map(其他消息，如联系人申请，朋友圈等)
  late final RxMap<String, int> otherUnreadCount;
  // 聊天消息总未读数量
  final chatUnreadTotal = 0.obs;
  // 通讯录总未读数量
  final contactUnreadTotal = 0.obs;
  // 发现总未读数量
  final discoverUnreadTotal = 0.obs;

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
    final otherSaved = _storage.read('otherUnreadCount');
    if (otherSaved != null && otherSaved is Map<String, dynamic>) {
      // 将 Map<String, dynamic> 转换为 Map<String, int>
      final converted = otherSaved.map((key, value) {
        // 确保 value 是 int，如果不是则尝试转换或设为 0
        final intValue = (value as int?) ?? 0;
        return MapEntry(key, intValue);
      });
      otherUnreadCount = RxMap<String, int>.from(converted);
    } else {
      otherUnreadCount = RxMap<String, int>();
    }
    // 第一次计算
    chatUnreadTotal.value = _calcChatUnreadTotal();
    contactUnreadTotal.value = otherUnreadCount.keys.fold(0, (sum, key) {
      if ([UnreadType.contactApply].contains(key)) {
        return sum + otherUnreadCount[key]!;
      }
      return sum;
    });
    discoverUnreadTotal.value = otherUnreadCount.keys.fold(0, (sum, key) {
      if ([UnreadType.share].contains(key)) {
        return sum + otherUnreadCount[key]!;
      }
      return sum;
    });
    // 监听变化并持久化
    ever(unreadCount, (_) {
      chatUnreadTotal.value = _calcChatUnreadTotal();
      _storage.write('unreadCount', unreadCount);
    });
    // 会话列表加载/更新(如切换免打扰)时重新计算聊天总未读
    final sessionStore = Get.find<ChatSessionStore>();
    ever(sessionStore.sessionList, (_) {
      chatUnreadTotal.value = _calcChatUnreadTotal();
    });
    ever(otherUnreadCount, (_) {
      contactUnreadTotal.value = otherUnreadCount.keys.fold(0, (sum, key) {
        if ([UnreadType.contactApply].contains(key)) {
          return sum + otherUnreadCount[key]!;
        }
        return sum;
      });
      discoverUnreadTotal.value = otherUnreadCount.keys.fold(0, (sum, key) {
        if ([UnreadType.share].contains(key)) {
          return sum + otherUnreadCount[key]!;
        }
        return sum;
      });
      _storage.write('otherUnreadCount', otherUnreadCount);
    });
  }

  // 计算聊天总未读（免打扰会话的未读不计入tab角标，参考微信）
  int _calcChatUnreadTotal() {
    final sessionStore = Get.find<ChatSessionStore>();
    // 免打扰会话的sessionId集合
    final disturbedIds = sessionStore.sessionList
        .where((s) => s.disturb == DisturbStatusEnum.open)
        .map((s) => s.sessionId)
        .toSet();
    return unreadCount.entries.fold(0, (sum, entry) {
      if (disturbedIds.contains(entry.key)) {
        return sum;
      }
      return sum + entry.value;
    });
  }

  // 新增指定会话的未读消息数量
  void addSessionUnreadCount(String sessionId) {
    addSessionUnreadCountByStep(sessionId, 1);
  }

  void addSessionUnreadCountByStep(String sessionId, int count) {
    unreadCount[sessionId] = (unreadCount[sessionId] ?? 0) + count;
  }

  // 清零指定会话未读消息数量
  void clearSessionUnreadCount(String sessionId) {
    unreadCount[sessionId] = 0;
  }

  // 新增指定消息类型未读数量
  void addUnreadCount(String unreadType) {
    addUnreadCountByStep(unreadType, 1);
  }

  // 新增指定消息类型未读数量
  void addUnreadCountByStep(String unreadType, int count) {
    otherUnreadCount[unreadType] = (otherUnreadCount[unreadType] ?? 0) + count;
  }

  // 清零指定消息类型未读数量
  void clearUnreadCount(String unreadType) {
    otherUnreadCount[unreadType] = 0;
  }
}

// 未读消息类型
class UnreadType {
  // 联系人申请
  static final contactApply = 'contactApply';
  // 朋友圈
  static final share = 'share';
}
