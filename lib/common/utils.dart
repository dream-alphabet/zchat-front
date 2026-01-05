// 转换时间戳为字符串
String formatTimestamp(int millisecondsTimestamp) {
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
