// 联系人状态枚举
class UserContactStatusEnum {
  // 非好友
  static const notFriend = 0;
  // 好友
  static const friend = 1;
  // 已删除好友
  static const delete = 2;
  // 被好友删除
  static const beDeleted = 3;
  // 已拉黑好友
  static const block = 4;
  // 被好友拉黑
  static const beBlocked = 5;
}

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

// 添加类型枚举
class JoinTypeEnum {
  // 直接添加，无需审核
  static const directAdd = 0;
  // 需要审核
  static const needCheck = 1;
}

// 消息免打扰状态枚举
class DisturbStatusEnum {
  // 关闭免打扰（开启提醒）
  static const close = 0;
  // 开启免打扰
  static const open = 1;
}

// 朋友圈权限枚举（仅好友有效）
class ContactPermissionEnum {
  // 允许看朋友圈
  static const allowMoments = 0;
  // 仅聊天
  static const onlyChat = 1;

  // 获取权限文本
  static String getText(int permission) {
    switch (permission) {
      case allowMoments:
        return '允许看朋友圈';
      case onlyChat:
        return '仅聊天';
      default:
        return '允许看朋友圈';
    }
  }
}
