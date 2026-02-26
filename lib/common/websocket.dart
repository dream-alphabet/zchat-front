import 'package:flutter_websocket_plus/flutter_websocket_plus.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/stores/token.dart';

WebSocketManager? manager;

// 初始化websocket连接
Future<void> initWebsocket() async {
  final token = tokenManager.getToken();
  // websocket连接地址
  final url = '${GlobalConstants.wsUrl}?token=$token';
  // websocket连接配置
  final config = WebSocketConfig(
    url: url,
    enableHeartbeat: true,  // 启用心跳机制
    heartbeatInterval: Duration(seconds: 1),  // 心跳间隔
    enableReconnection: true,  // 启用重连机制
    maxReconnectionAttempts: 5,  // 最大重连次数
    maxReconnectionDelay: Duration(seconds: 1),  // 重连间隔
  );
  manager = WebSocketManager(config: config);
  // 等待连接
  await manager?.connect();
  // 监听事件
  manager?.eventStream.listen((event) {
    switch (event.type) {
      case 'connected':
        print('$url, 连接成功');
        break;
      case 'disconnected':
        print('websocket连接断开');
        break;
      case 'reconnecting':
        print('正在重新连接... ${event.data}');
        break;
      case 'error':
        print('连接出错: ${event.data}');
        break;
    }
  });
}
