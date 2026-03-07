import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zchat/api/chat.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/emoji.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/chat.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/chat.dart';
import 'package:zchat/model/enums/contact.dart';
import 'package:zchat/pages/chat/widgets/chat_message.dart';
import 'package:zchat/widgets/page_header.dart';

// 聊天消息页面
class ChatMessagePage extends StatefulWidget {
  const ChatMessagePage({super.key});

  @override
  State<ChatMessagePage> createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  // 联系人id(用户/群聊)
  String _contactId = '';
  // 联系人类型
  int _contactType = UserContactTypeEnum.user;
  // 联系人信息
  ContactInfoRes? _contactInfo;
  // 是否显示表情区域
  bool _showEmotion = false;
  // 是否显示更多区域
  bool _showMore = false;
  // 是否显示语音
  bool _showVoice = false;
  // 消息输入框控制器
  final _messageController = TextEditingController();
  // 消息输入框焦点控制器
  final _messageFocusNode = FocusNode();
  // 文本消息
  String _msg = '';
  // 页码
  int _page = 1;
  // 每页条数
  final _pageSize = 15;
  // 消息列表
  List<ChatMessageRes> _msgList = [];
  // 消息列表滚动控制器
  final _msgListController = ScrollController();

  // 发送文件消息
  void _sendFile() async {
    // 选择文件(可以选择多个)
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    // 用户选择了文件
    if (result != null) {
      print('选择的文件: ${result.files}');
    }
  }

  // 发送图片消息
  void _sendImage(ImageSource source) async {
    // 从相册中获取图片
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      print('image path:${image.path}');
    }
  }

  // 发送个人名片
  void _sendPersonCard() {
    print('发送个人名片');
  }

  // 视频通话
  void _videoCall() {
    print('视频通话');
  }

  @override
  void initState() {
    super.initState();
    // 接收联系人id和联系人类型参数
    Future.microtask(() {
      if (ModalRoute.of(context) != null) {
        final params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        _contactId = params['contactId'];
        _contactType = params['contactType'];
        _getContactInfo();
        _getMsgList();
        _msgListController.addListener(() {
          if (_msgListController.offset >= 70.w) {
            print('获取下一页数据');
          }
        });
      }
    });
  }

  // 获取消息列表
  Future<void> _getMsgList() async {
    final res = await getMessageListApi(
      GetMsgListReq(page: _page, pageSize: _pageSize, contactId: _contactId),
    );
    _msgList = res.list.map((msg) => ChatMessageRes.fromJson(msg)).toList();
    setState(() {});
    _scrollToBottom();
  }

  // 获取联系人信息
  Future<void> _getContactInfo() async {
    final contactInfo = await getContactInfoApi(_contactId);
    // 结果为空
    if (contactInfo == null) {
      ToastUtils.showGlobalToast(msg: '没有查询到该联系人信息');
      Navigator.pop(context);
      return;
    }
    _contactInfo = contactInfo;
    setState(() {});
  }

  // 滚动到底部
  void _scrollToBottom() {
    // 等待当前帧绘制完成后再滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _msgListController.jumpTo(0);
    });
  }

  // 发送文本消息
  void _sendText() async {
    // 如果消息为空
    if (_msg.isBlank == true) {
      ToastUtils.showGlobalToast(msg: '消息不能为空');
      return;
    }
    // 发送消息
    await sendMessageApi(
      SendMsgReq(
        contactId: _contactId,
        contactType: _contactType,
        messageType: MessageTypeEnum.text.type,
        messageContent: _msg,
      ),
    );
    // 清空输入框
    setState(() {
      _messageController.clear();
      _msg = '';
    });
  }

  // 消息列表
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _msgListController,
      itemCount: _msgList.length,
      reverse: true,
      itemBuilder: (ctx, index) => ChatMessage(message: _msgList[index]),
    );
  }

  // 语音录入区域
  Widget _buildVoice() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.white,
      ),
      padding: EdgeInsets.all(6.w),
      alignment: Alignment.center,
      child: Text(
        '按住 说话',
        style: TextStyle(color: Colors.black, fontSize: 16.sp),
      ),
    );
  }

  // 输入框
  Widget _buildInput() {
    return TextField(
      controller: _messageController,
      focusNode: _messageFocusNode,
      onChanged: (value) {
        setState(() {
          _msg = value;
        });
      },
      onSubmitted: (value) {
        _sendText();
      },
      onTap: () {
        setState(() {
          _showVoice = false;
          _showMore = false;
          _showEmotion = false;
        });
      },
      textInputAction: TextInputAction.send,
      maxLength: 300,
      maxLines: 3,
      minLines: 1,
      // 隐藏计数文本
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => SizedBox(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.all(6.w),
        isDense: true,
      ),
    );
  }

  // 发送按钮
  Widget _buildSendBtn() {
    return GestureDetector(
      onTap: () {
        _sendText();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5.w, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Color.fromRGBO(20, 134, 237, 1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          '发送',
          style: TextStyle(fontSize: 15.sp, color: Colors.white),
        ),
      ),
    );
  }

  // emoji表情区域
  Widget _buildEmoji() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 200.w,
          child: GridView.builder(
            itemCount: supportEmojiList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 5.w,
              mainAxisSpacing: 5.w,
            ),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                setState(() {
                  _messageController.text += supportEmojiList[index];
                  _msg += supportEmojiList[index];
                });
              },
              child: Text(
                supportEmojiList[index],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: GestureDetector(
              onTap: () {
                // 消息为空
                if (_msg.isEmpty) {
                  return;
                }
                // 删除最后一个字符
                setState(() {
                  _messageController.text = _messageController.text.characters
                      .skipLast(1)
                      .toString();
                  _msg = _msg.characters.skipLast(1).toString();
                });
              },
              child: Icon(
                MyIcon.backspace,
                color: _msg.isNotEmpty
                    ? Colors.black
                    : Color.fromRGBO(237, 237, 237, 1),
                size: 25.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建更多功能项
  Widget _buildMoreItem(MoreItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        spacing: 5.w,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, size: 25.w, color: Colors.black),
          ),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 10.sp,
              color: Color.fromRGBO(144, 144, 144, 1),
            ),
          ),
        ],
      ),
    );
  }

  // 更多区域
  Widget _buildMore() {
    // 更多功能列表
    final moreItems = [
      MoreItem(
        name: '相册',
        icon: MyIcon.gallery,
        onTap: () {
          _sendImage(ImageSource.gallery);
        },
      ),
      MoreItem(
        name: '摄像头',
        icon: MyIcon.camera,
        onTap: () {
          _sendImage(ImageSource.camera);
        },
      ),
      MoreItem(name: '视频通话', icon: MyIcon.videoCall, onTap: _videoCall),
      MoreItem(name: '个人名片', icon: MyIcon.personCard, onTap: _sendPersonCard),
      MoreItem(name: '文件', icon: MyIcon.file, onTap: _sendFile),
    ];

    return SizedBox(
      width: double.infinity,
      height: 200.w,
      child: Center(
        child: GridView.count(
          shrinkWrap: true, // 让GridView根据内容调整高度
          physics: NeverScrollableScrollPhysics(), // 禁止滚动
          crossAxisCount: 4,
          mainAxisSpacing: 10.w,
          children: List.generate(
            moreItems.length,
            (index) => _buildMoreItem(moreItems[index]),
          ),
        ),
      ),
    );
  }

  // 键盘图标
  Widget _buildKeyboardIcon() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showVoice = false;
          _showMore = false;
          _showEmotion = false;
        });
        // 等待当前帧绘制完成后再请求焦点
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_messageFocusNode);
          // 主动显示软键盘
          SystemChannels.textInput.invokeMethod('TextInput.show');
        });
      },
      child: Icon(MyIcon.keyboard, size: 30.w),
    );
  }

  // 底部操作区域
  Widget _buildBottom() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      color: Color.fromRGBO(247, 247, 247, 1),
      child: Column(
        children: [
          Row(
            spacing: 6.w,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _showVoice
                  ? _buildKeyboardIcon()
                  : GestureDetector(
                      onTap: () {
                        // 使得输入框失去焦点
                        FocusScope.of(context).unfocus();
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        setState(() {
                          _showVoice = true;
                          _showMore = false;
                          _showEmotion = false;
                        });
                      },
                      child: Icon(MyIcon.voice, size: 30.w),
                    ),
              Expanded(child: _showVoice ? _buildVoice() : _buildInput()),
              _showEmotion
                  ? _buildKeyboardIcon()
                  : GestureDetector(
                      onTap: () {
                        // 隐藏软键盘
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        setState(() {
                          _showVoice = false;
                          _showMore = false;
                          _showEmotion = true;
                        });
                      },
                      child: Icon(MyIcon.emotion, size: 30.w),
                    ),
              _msg.isEmpty
                  ? (_showMore
                        ? _buildKeyboardIcon()
                        : GestureDetector(
                            onTap: () {
                              // 输入框失去焦点
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _showVoice = false;
                                _showMore = true;
                                _showEmotion = false;
                              });
                            },
                            child: Icon(MyIcon.messageAdd, size: 30.w),
                          ))
                  : _buildSendBtn(),
            ],
          ),
          if (_showEmotion || _showMore) SizedBox(height: 10.w),
          // emoji
          Offstage(offstage: !_showEmotion, child: _buildEmoji()),
          // 更多
          Offstage(offstage: !_showMore, child: _buildMore()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 拦截所有返回上一页，自定义处理
      onPopInvokedWithResult: (didPop, _) {
        // 如果已经返回，则无需处理
        if (didPop) {
          return;
        }
        // 如果当前输入框还持有焦点，失去焦点，如果没有，返回上一页
        if (_messageFocusNode.hasFocus) {
          FocusScope.of(context).unfocus();
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Color.fromRGBO(237, 237, 237, 1),
          foregroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color.fromRGBO(237, 237, 237, 1),
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Color.fromRGBO(
              247,
              247,
              247,
              1,
            ), // 底部导航栏背景
            systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
          ),
        ),
        backgroundColor: Color.fromRGBO(237, 237, 237, 1),
        body: SafeArea(
          child: Column(
            children: [
              // 导航栏
              PageHeader(
                title: _contactInfo?.contactName ?? '',
                showLeftBackIcon: true,
                backgroundColor: Color.fromRGBO(237, 237, 237, 1),
                rightIconList: [
                  GestureDetector(
                    onTap: () {
                      // 如果双方是好友关系，跳转到好友设置页面
                      if (_contactType == UserContactTypeEnum.user) {
                        Navigator.pushNamed(context, RoutePath.friendSetting);
                      } else if (_contactType == UserContactTypeEnum.group) {
                        // 如果是群聊，跳转到群聊设置页面
                        Navigator.pushNamed(context, RoutePath.groupSetting);
                      }
                    },
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 25.w,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Expanded(child: _buildMessageList()),
              _buildBottom(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }
}

// 更多功能项
class MoreItem {
  final String name;
  final IconData icon;
  final void Function() onTap;

  MoreItem({required this.name, required this.icon, required this.onTap});
}
