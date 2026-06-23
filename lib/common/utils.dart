import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/routes/index.dart';

// 转换时间戳为字符串
String formatTimestamp(int? millisecondsTimestamp) {
  if (millisecondsTimestamp == null) {
    return '';
  }
  // 将毫秒时间戳转换为 DateTime 对象
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
    millisecondsTimestamp,
  );
  DateTime now = DateTime.now();

  // 判断是否同一天
  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    // 同一天：返回时分格式（HH:mm）
    // 确保小时和分钟都是两位数
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  // 判断是否同一年
  else if (dateTime.year == now.year) {
    // 同一年：返回月日格式（MM月dd日）
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    return '$month月$day日';
  }
  // 不同年
  else {
    // 返回年月日格式（yyyy年MM月dd日）
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}年$month月$day日';
  }
}

// 邮箱校验
bool isValidEmail(String? email) {
  if (email == null) {
    return false;
  }
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
    multiLine: false,
  );
  return emailRegex.hasMatch(email);
}

// 复制文本到剪切板
Future<void> copyText(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  ToastUtils.showGlobalToast(msg: '已复制');
}

// 发送静默通知栏消息
Future<void> sendTestNotification() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        importance: Importance.min,
        priority: Priority.min,
        playSound: false,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: '静默发送通知',
    body: '这是一条开启权限的静默通知消息',
    notificationDetails: platformChannelSpecifics,
  );
}

// 请求通知栏权限
Future<void> requestNotificationPermission() async {
  // 查看是否已经授权
  var state = await Permission.notification.request();
  // 如果已经授权
  if (state.isGranted) {
    print('用户授权了');
    return;
  }
  // 发送静默通知栏消息，如果失败请求通知栏权限
  await sendTestNotification();
  // 请求通知栏权限
  state = await Permission.notification.request();
  if (state.isGranted) {
    print('用户授权了');
  } else {
    print('用户没授权');
  }
}

// 全局页面跳转
void navigateToPage(String routePath, {Map<String, dynamic>? arguments}) {
  Navigator.pushNamed(
    globalNavigatorKey.currentState!.context,
    routePath,
    arguments: arguments,
  );
}

// 判断是否为英文字母
bool isEnglish(String char) {
  return RegExp(r'^[A-Za-z]$').hasMatch(char);
}

// 判断是否为中文字符（基本汉字 Unicode 范围）
bool isChinese(String char) {
  return RegExp(r'^[\u4e00-\u9fa5]$').hasMatch(char);
}

// 获取单个联系人的分组Key(A-Z, #)
String getGroupKey(String name) {
  // 空字符串
  if (name.trim().isEmpty) {
    return '#';
  }
  // 第一个字符
  final firstChar = name.trim().substring(0, 1);
  // 如果是英文，直接转大写
  if (isEnglish(firstChar)) {
    return firstChar.toUpperCase();
  }
  // 如果是中文，取拼音首字母大写
  if (isChinese(firstChar)) {
    // 获取首字母拼音
    final pinyin = PinyinHelper.getFirstWordPinyin(firstChar);
    if (pinyin.isNotEmpty) {
      return pinyin.substring(0, 1).toUpperCase();
    }
    // 转换失败
    return '#';
  }
  // 既不是中文也不是英文
  return '#';
}

// 获取分组后的联系人列表
Map<String, List<UserContactRes>> getGroupedContacts(
  List<UserContactRes> contacts,
) {
  // 分组
  Map<String, List<UserContactRes>> map = {};
  for (final contact in contacts) {
    final key = getGroupKey(contact.contactName);
    map.putIfAbsent(key, () => []);
    map[key]!.add(contact);
  }
  // 对key进行排序
  final sortedKeys = map.keys.toList();
  sortedKeys.sort((a, b) {
    if (a == '#') return 1;
    if (b == '#') return -1;
    return a.compareTo(b);
  });
  Map<String, List<UserContactRes>> sortedGroups = {};
  for (final key in sortedKeys) {
    sortedGroups[key] = map[key]!;
  }
  return sortedGroups;
}

// 防抖工具类
class Debouncer {
  final Duration timeout;
  Timer? _timer;

  Debouncer({required this.timeout});

  void run(VoidCallback action) {
    // 取消上一个定时器，保证在指定时间内只有最后一次调用有效
    _timer?.cancel();
    _timer = Timer(timeout, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
