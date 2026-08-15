import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

// 通话铃声/振动提示工具（微信风格：呼叫/响铃时铃声+周期振动，接听/挂断时短振动）
class CallTone {
  CallTone._();

  // 来电铃声播放器
  static final _ringtonePlayer = AudioPlayer();
  // 呼叫等待音播放器
  static final _waitingPlayer = AudioPlayer();
  // 周期振动定时器
  static Timer? _vibrateTimer;

  // 开始周期振动（微信来电振动效果）
  static void _startVibrate() {
    _vibrateTimer?.cancel();
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      Vibration.vibrate(duration: 500);
    });
  }

  // 停止周期振动
  static void _stopVibrate() {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    Vibration.cancel();
  }

  // 停止所有铃声和振动
  static Future<void> stop() async {
    _stopVibrate();
    try {
      await _ringtonePlayer.stop();
      await _waitingPlayer.stop();
    } catch (_) {
      // 播放器异常忽略
    }
  }

  // 播放来电铃声（被叫方响铃，循环播放+周期振动）
  static Future<void> startRingtone() async {
    await stop();
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(
        AssetSource('lib/assets/sounds/call_ringtone.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // 播放失败不阻塞通话
    }
    _startVibrate();
  }

  // 播放呼叫等待音（呼叫方等待接听，循环播放+周期振动）
  static Future<void> startWaitingTone() async {
    await stop();
    try {
      await _waitingPlayer.setReleaseMode(ReleaseMode.loop);
      await _waitingPlayer.play(
        AssetSource('lib/assets/sounds/call_waiting.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // 播放失败不阻塞通话
    }
    _startVibrate();
  }

  // 短振动一次（接听/挂断提示）
  static Future<void> vibrate() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 120);
    }
  }
}
