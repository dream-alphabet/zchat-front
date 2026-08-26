# zchat 前端（Flutter）

微信风格的即时通讯 App 前端，配合 [zchat 后端](../backend) 使用。

## 项目简介

使用 Flutter 开发的聊天应用，覆盖主流 IM 功能：

- **单聊 / 群聊**：文字、图片、视频、文件、语音消息，合并转发，多选消息，消息搜索定位
- **实时通信**：WebSocket 消息实时推送、会话未读计数、输入中状态（机器人）
- **朋友圈**：图文发布、点赞评论、背景图、个人主页
- **音视频通话**：基于 WebRTC 的一对一视频/语音通话（需自建 TURN 服务器）
- **AI 机器人**：内置机器人（zchat机器人），支持多模态（文字/图片），markdown 渲染回复
- **社交**：好友申请/验证、备注、拉黑、仅聊天、群管理（改名/公告/二维码/退群解散）
- **工具**：扫一扫（二维码）、我的二维码、搜索（用户/群聊/聊天记录）

## 技术栈

| 分类 | 技术 |
|------|------|
| 框架 | Flutter / Dart |
| 状态管理 | GetX |
| 网络 | dio、web_socket_channel |
| 音视频 | flutter_webrtc（通话）、video_player（播放）、record（语音消息）、audioplayers（铃声） |
| 媒体 | image_picker、image_cropper、gal（保存相册）、photo_view（预览） |
| 其他 | permission_handler、mobile_scanner、flutter_markdown、flutter_screenutil、get_storage、shared_preferences |

## 环境要求

- Flutter 3.44+（Dart 3.12+）
- Android：minSdk 24（Flutter 默认），targetSdk 跟随 Flutter 版本
- iOS：部署目标 13.0
- 需要先启动后端服务（见 [后端 README](../backend/README.md)）

## Quick Start

```bash
# 1. 修改后端地址（默认指向局域网开发机）
#    front/lib/common/constants.dart 中：
#    static const host = '192.168.2.103';  ← 改成你的后端 IP 或域名

# 2. 拉取依赖
flutter pub get

# 3. 运行（Android 真机/模拟器）
flutter run
```

首次使用请在 App 内注册账号（邮箱 + 昵称 + 密码，含图形验证码），注册需后端在线。

## 功能模块

```
lib/
├── api/           # 接口封装（dio）
├── common/        # 常量、工具、websocket 客户端、全局事件
├── model/         # 数据模型与枚举
├── pages/
│   ├── auth/      # 登录/注册
│   ├── main/      # 主页（会话/联系人/发现/我的）
│   ├── chat/      # 聊天页、通话页、聊天记录
│   ├── contact/   # 联系人、群管理、好友设置
│   ├── discover/  # 朋友圈、扫一扫
│   └── my/        # 个人资料、二维码
├── stores/        # GetX 状态（用户/会话/token）
└── widgets/       # 通用组件（头像、朋友圈卡片等）
```

## 注意事项

- **iOS 未经过真机测试**：当前只在 Android 真机上验证过。iOS 构建需 macOS + Xcode + CocoaPods，`Info.plist` 的权限描述（相机/麦克风/相册）已配置，但未经真机验证，如遇问题请提 issue。
- **应用包名**：`code.dream.zchat`（Android applicationId / iOS bundle id）
- **发布签名**：Android release 构建默认使用 debug 签名，正式发布前请在 `android/app/build.gradle.kts` 配置正式签名。
- **网络**：开发环境使用明文 HTTP/WS（`usesCleartextTraffic` / ATS 已放开），生产环境请配置 HTTPS/WSS。
- **音视频通话**：需要可公网访问的 TURN 服务器（见后端部署说明），否则仅局域网内可通话。
- **图片内存**：消息列表图片按显示尺寸解码（cacheWidth），避免大图全分辨率加载。
