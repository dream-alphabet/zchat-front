import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// 语音播放管理器（单例，互斥播放）
class VoicePlayer {
  VoicePlayer._();

  // 单例
  static final VoicePlayer instance = VoicePlayer._();

  // 音频播放器
  final AudioPlayer _player = AudioPlayer();

  // 当前正在播放的语音消息key，null表示没有播放
  final ValueNotifier<String?> playingKey = ValueNotifier<String?>(null);

  // 是否已监听播放状态
  bool _listening = false;

  void _ensureListeners() {
    if (_listening) {
      return;
    }
    _listening = true;
    _player.eventStream.listen(
      (event) {
        // 播放完成时清除播放状态
        if (event.eventType == AudioEventType.complete) {
          playingKey.value = null;
        }
      },
      // 播放出错时清除播放状态
      onError: (Object e, [StackTrace? stackTrace]) => playingKey.value = null,
    );
  }

  // 播放语音消息，再次点击同一条会停止
  Future<void> play({required String key, required String url}) async {
    _ensureListeners();
    // 正在播放同一条，停止
    if (playingKey.value == key) {
      await _player.stop();
      playingKey.value = null;
      return;
    }
    // 停止正在播放的语音
    await _player.stop();
    playingKey.value = key;
    try {
      await _player.play(UrlSource(url));
    } catch (_) {
      // 播放失败(如网络错误)，清除播放状态
      playingKey.value = null;
    }
  }

  // 停止播放
  Future<void> stop() async {
    await _player.stop();
    playingKey.value = null;
  }
}
