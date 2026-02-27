import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/api/contact.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/common/icon.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/model/contact.dart';
import 'package:zchat/model/enums/contact.dart';
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
      }
    });
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

  // 发送文本消息
  void _sendText() {
    print('消息: ${_messageController.text}');
  }

  // 消息列表
  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: 10000,
      itemBuilder: (ctx, index) => Container(
        width: double.infinity,
        height: 40.w,
        color: Colors.blue,
        alignment: Alignment.center,
        child: Text('消息${index + 1}', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // 语音录入区域
  Widget _buildVoice() {
    return Text('语音录入区域');
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

  // 功能区域
  Widget _buildFunction() {
    if (_showEmotion) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _messageController.text += '1';
            _msg += '1';
          });
        },
        child: Text('表情'),
      );
    } else if (_showMore) {
      return Text('更多');
    } else {
      return SizedBox();
    }
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
        spacing: 10.w,
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
          if (_showEmotion || _showMore) _buildFunction(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,  // 拦截所有返回上一页，自定义处理
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
