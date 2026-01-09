import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/api/user.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/model/user.dart';
import 'package:zchat/widgets/base64_image.dart';
import 'package:zchat/widgets/page_header.dart';

// 注册页面
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 昵称输入框控制器
  final _nicknameController = TextEditingController();
  // 邮箱输入框控制器
  final _emailController = TextEditingController();
  // 密码输入框控制器
  final _passwordController = TextEditingController();
  // 再次输入密码控制器
  final _rePasswordController = TextEditingController();
  // 验证码输入框控制器
  final _captchaController = TextEditingController();
  // 图形验证码(base64)
  String _captcha = '';
  // 图形验证码key
  String _captchaKey = '';

  @override
  void initState() {
    super.initState();
    _getCaptcha();
  }

  // 获取图形验证码
  Future<void> _getCaptcha() async {
    final res = await getCaptchaApi();
    setState(() {
      _captcha = res.captcha;
      _captchaKey = res.captchaKey;
    });
  }

  // 构建图形验证码输入框
  Widget _buildCaptchaInput() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextField(
            controller: _captchaController,
            cursorColor: Colors.black,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color.fromRGBO(242, 242, 242, 1),
              hintText: '请输入验证码',
              hintStyle: TextStyle(
                color: Color.fromRGBO(122, 122, 122, 1),
                fontSize: 16.sp,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Base64Image(base64String: _captcha, onRefreshCaptcha: _getCaptcha),
      ],
    );
  }

  // 注册
  Future<void> _resgiter() async {
    // 数据校验
    final nickname = _nicknameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final rePassword = _rePasswordController.text;
    final userCaptcha = _captchaController.text;
    // 数据校验
    if (nickname.length < 5 || nickname.length > 12) {
      return ToastUtils.showGlobalToast(msg: '昵称长度应为5-12位');
    }
    if (!isValidEmail(email)) {
      return ToastUtils.showGlobalToast(msg: '邮箱格式不正确');
    }
    if (password.length < 8 || password.length > 20) {
      return ToastUtils.showGlobalToast(msg: '密码长度应为8-20位');
    }
    if (password != rePassword) {
      return ToastUtils.showGlobalToast(msg: '两次密码输入不一致');
    }
    if (userCaptcha.isEmpty) {
      return ToastUtils.showGlobalToast(msg: '验证码不能为空');
    }
    try {
      await registerApi(
        RegisterReq(
          nickname: nickname,
          email: email,
          password: password,
          captchaKey: _captchaKey,
          userCaptcha: userCaptcha,
        ),
      );
      ToastUtils.showGlobalToast(msg: '注册成功');
      // 退回上一页
      Navigator.pop(context);
    } catch (e) {
      _getCaptcha();
    }
  }

  // 构建注册按钮
  Widget _buildRegisterBtn() {
    return GestureDetector(
      onTap: _resgiter,
      child: Container(
        width: double.infinity,
        height: 48.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.w),
          color: Color.fromRGBO(0, 95, 255, 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '注册',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white, // 底部导航栏背景
          systemNavigationBarIconBrightness: Brightness.dark, // 底部导航栏图标颜色
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              PageHeader(
                title: '注册',
                showRightIcon: false,
                showLeftBackIcon: true,
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: 16.w,
                  vertical: 10.w,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nicknameController,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(242, 242, 242, 1),
                        hintText: '请输入昵称',
                        hintStyle: TextStyle(
                          color: Color.fromRGBO(122, 122, 122, 1),
                          fontSize: 16.sp,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.w),
                    // 邮箱
                    TextField(
                      controller: _emailController,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(242, 242, 242, 1),
                        hintText: '请输入邮箱',
                        hintStyle: TextStyle(
                          color: Color.fromRGBO(122, 122, 122, 1),
                          fontSize: 16.sp,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.w),
                    // 密码
                    TextField(
                      controller: _passwordController,
                      cursorColor: Colors.black,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(242, 242, 242, 1),
                        hintText: '请输入密码',
                        hintStyle: TextStyle(
                          color: Color.fromRGBO(122, 122, 122, 1),
                          fontSize: 16.sp,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.w),
                    TextField(
                      controller: _rePasswordController,
                      cursorColor: Colors.black,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(242, 242, 242, 1),
                        hintText: '请再次输入密码',
                        hintStyle: TextStyle(
                          color: Color.fromRGBO(122, 122, 122, 1),
                          fontSize: 16.sp,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.w),
                    _buildCaptchaInput(),
                    SizedBox(height: 20.w),
                    // 注册按钮
                    _buildRegisterBtn(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
