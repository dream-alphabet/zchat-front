// 全局常量类
class GlobalConstants {
  // 主机地址
  static const host = '192.168.2.101';
  // api请求基础地址
  static const baseUrl = 'http://$host/api';
  // ws连接地址
  static const wsUrl = 'ws://$host/ws';
  // 文件访问基础地址
  static const fileUrl = 'http://$host/files';
  // 头像文件访问地址
  static const avatarUrl = '$fileUrl/avatar';
  // 消息文件访问地址
  static const msgFileUrl = '$fileUrl/messages';
  // 默认用户头像
  static const defaultAvatar = 'lib/assets/images/default_user.png';
  // 超时时间
  static const timeout = 5;
  // 业务状态
  // 成功状态
  static const successCode = 200;
  // 文件大小限制(单位: 字节)
  // 图片不能大于50MB
  static const imageMaxMB = 50;
  static const imageMaxSize = imageMaxMB * 1000 * 1000;
  // 视频不能大于100MB
  static const videoMaxMB = 100;
  static const videoMaxSize = videoMaxMB * 1000 * 1000;
  // 其余文件不能大于100MB
  static const fileMaxMB = 100;
  static const fileMaxSize = fileMaxMB * 1000 * 1000;
  // 支持的媒体格式
  // 图片格式
  static const imageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
  // 视频格式
  static const videoFormats = ['mp4'];
  // 撤回时间限制(5分钟)
  static const recallLimit = 5 * 60 * 1000;
}

// api请求路径常量
class Api {
  static const getCaptcha = '/user/captcha';
  static const login = '/user/login';
  static const register = '/user/register';
  static const getUserInfo = '/user/userInfo';
  static const updateUserAvatar = '/user/updateAvatar';
  static const searchContactExist = '/contact/searchExist';
  static const getContactInfo = '/contact/contactInfo';
  static const sendContactApply = '/contact/sendApply';
  static const getContactApplyList = '/contact/apply';
  static const handleApply = '/contact/apply/handle';
  static const getContactList = '/contact/list';
  static const searchContact = '/contact/search';
  static const delContact = '/contact/delete';
  static const getChatSessionList = '/chat/session/list';
  static const sendMessage = '/chat/send';
  static const recallMessage = '/chat/message/recall/';
  static const getMsgList = '/chat/message/list';
  static const shareMessage = '/chat/message/share';
  static const createGroup = '/group/create';
  static const getGroupSettings = '/group/settings/';
  static const searchGroupMember = '/group/searchMember';
  static const dissolveGroup = '/group/dissolve/';
}

// 路由路径常量
class RoutePath {
  // 主页面
  static const main = 'main';
  // 登录
  static const login = 'login';
  // 注册
  static const register = 'register';
  // 新的朋友(查看好友申请)
  static const newFriend = 'newFriend';
  // 仅聊天的朋友
  static const onlyChatFriend = 'onlyChatFriend';
  // 群聊(查看加入的群聊)
  static const groupChat = 'groupChat';
  // 联系人信息(用户/群聊)
  static const contactInfo = 'contactInfo';
  // 朋友圈
  static const moments = 'moments';
  // 扫一扫
  static const scan = 'scan';
  // 添加朋友
  static const addFriend = 'addFriend';
  // 创建群聊
  static const createGroup = 'createGroup';
  // 搜索好友(用户/群聊)
  static const searchContact = 'searchContact';
  // 我的二维码
  static const myQRCode = 'myQRCode';
  // 用户中心
  static const my = 'my';
  // 好友设置
  static const friendSetting = 'friendSetting';
  // 群聊设置
  static const groupSetting = 'groupSetting';
  // 添加到通讯录
  static const addContact = 'addContact';
  // 验证联系人申请
  static const verifyApply = 'verifyApply';
  // 聊天消息
  static const chatMessage = 'chatMessage';
  // 视频通话
  static const videoCall = 'videoCall';
  // 语音通话
  static const voiceCall = 'voiceCall';
  // 选择联系人
  static const contactSelect = 'contactSelect';
  // 群名称
  static const groupName = 'groupName';
  // 群公告
  static const groupNotice = 'groupNotice';
  // 群备注
  static const groupRemark = 'groupRemark';
  // 群二维码
  static const groupQrcode = 'groupQrcode';
}
