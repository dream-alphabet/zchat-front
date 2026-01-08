// 图形验证码响应结果
class CaptchaRes {
    String captcha;
    String captchaKey;

    CaptchaRes({
        required this.captcha,
        required this.captchaKey,
    });

    factory CaptchaRes.fromJson(Map<String, dynamic> json) => CaptchaRes(
        captcha: json["captcha"],
        captchaKey: json["captchaKey"],
    );
}