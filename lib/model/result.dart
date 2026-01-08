// 统一响应结果
class Result {
    int code;
    String msg;
    Map<String, dynamic> data;

    Result({
        required this.code,
        required this.msg,
        required this.data,
    });

    factory Result.fromJson(Map<String, dynamic> json) => Result(
        code: json["code"],
        msg: json["msg"],
        data: json["data"],
    );
}