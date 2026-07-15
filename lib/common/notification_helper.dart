import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 通知栏工具类
class NotificationHelper {
  // 使用单例模式进行初始化
  static final NotificationHelper _instance = NotificationHelper._internal();

  // 初始化工厂方法
  factory NotificationHelper() => _instance;

  NotificationHelper._internal();

  // FlutterLocalNotificationsPlugin是一个用于处理本地通知的插件，它提供了在Flutter应用程序中发送和接收本地通知的功能。
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 初始化函数
  Future<void> initialize() async {
    // AndroidInitializationSettings是一个用于设置Android上的本地通知初始化的类
    // 使用了app_icon作为参数，这意味着在Android上，应用程序的图标将被用作本地通知的图标。
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // 15.1是DarwinInitializationSettings，旧版本好像是IOSInitializationSettings（有些例子中就是这个）
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    // 初始化
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // 监听通知栏点击
  void _onNotificationTap(NotificationResponse response) {
    // 通知栏载荷
    final payload = response.payload;
    if (payload == null) {
      return;
    }
  }

  //  显示通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload
  }) async {
    // 安卓的通知
    // 用于指定通知通道的ID。
    // 用于指定通知通道的名称。
    // 用于指定通知通道的描述。
    // Importance.max：用于指定通知的重要性，设置为最高级别。
    // Priority.high：用于指定通知的优先级，设置为高优先级。
    // 'ticker'：用于指定通知的提示文本，即通知出现在通知中心的文本内容。
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'zchat_message',
          'zchat_message',
          channelDescription: 'zchat消息推送',
          importance: Importance.max,
          priority: Priority.high,
          ticker: '您有一条新消息',
        );

    // ios的通知
    const String darwinNotificationCategoryPlain = 'plainCategory';
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          categoryIdentifier: darwinNotificationCategoryPlain, // 通知分类
        );
    // 创建跨平台通知
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    // 发起一个通知
    await _notificationsPlugin.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload
    );
  }
}
