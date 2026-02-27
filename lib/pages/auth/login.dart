import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zchat/api/user.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/utils.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/user.dart';
import 'package:zchat/stores/token.dart';
import 'package:zchat/widgets/base64_image.dart';
import 'package:zchat/widgets/page_header.dart';

// 登录页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 邮箱输入框控制器
  final _emailController = TextEditingController();
  // 密码输入框控制器
  final _passwordController = TextEditingController();
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

  // 登录
  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final userCaptcha = _captchaController.text;
    // 数据校验
    if (!isValidEmail(email)) {
      return ToastUtils.showGlobalToast(msg: '邮箱格式不正确');
    }
    if (password.isEmpty) {
      return ToastUtils.showGlobalToast(msg: '密码不能为空');
    }
    if (userCaptcha.isEmpty) {
      return ToastUtils.showGlobalToast(msg: '验证码不能为空');
    }
    try {
      // 请求接口
      final res = await loginApi(
        LoginReq(
          email: email,
          password: password,
          captchaKey: _captchaKey,
          userCaptcha: userCaptcha,
        ),
      );
      // 存储token
      tokenManager.setToken(res.token);
      ToastUtils.showGlobalToast(msg: '登录成功');
      // 跳转到主页
      Navigator.pushNamedAndRemoveUntil(context, RoutePath.main, (route) => false);
    } catch (e) {
      _getCaptcha();
    }
  }

  // 构建登录按钮
  Widget _buildLoginBtn() {
    return GestureDetector(
      onTap: _login,
      child: Container(
        width: double.infinity,
        height: 48.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.w),
          color: Color.fromRGBO(0, 95, 255, 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '登录',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 构建图形验证码输入框
  Widget _buildCaptchaInput() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextField(
            controller: _captchaController,
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
        child: Column(
          children: [
            PageHeader(
              title: '登录',
              showRightIcon: false,
              showLeftBackIcon: false,
              backgroundColor: Colors.white,
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: 16.w,
                  vertical: 10.w,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 20.w),
                    // 邮箱
                    TextField(
                      controller: _emailController,
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
                    _buildCaptchaInput(),
                    SizedBox(height: 10.w),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          // 跳转到注册页面
                          Navigator.pushNamed(context, RoutePath.register);
                        },
                        child: Text(
                          '没有账号?',
                          style: TextStyle(
                            color: Color.fromRGBO(0, 95, 255, 1),
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.w),
                    // 登录按钮
                    _buildLoginBtn()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
