// 统一响应结果
class Result {
    int code;
    String msg;
    dynamic data;

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

// 分页响应结果
class PageRes {
  int pages;
  int total;
  List<dynamic> list;

  PageRes({
    required this.pages,
    required this.total,
    required this.list
  });

  factory PageRes.fromJson(Map<String, dynamic> json) => PageRes(
    pages: json['pages'], 
    total: json['total'], 
    list: json['list']
  );
}