// 联系人类型枚举
class UserContactTypeEnum {
  // 用户
  static const user = 0;
  // 群聊
  static const group = 1;
}

// 联系人申请状态枚举
class ContactApplyStatusEnum {
  // 待处理
  static const waitHandle = 0;
  // 已同意
  static const agree = 1;
  // 已拒绝
  static const reject = 2;

  // 获取状态文本
  static String getStatusText(int status) {
    switch (status) {
      case waitHandle:
        return '待处理';
      case agree:
        return '已同意';
      case reject:
        return '已拒绝';
      default:
        return '未知';
    }
  }
}
