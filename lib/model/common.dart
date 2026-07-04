// 统一响应结果
class Result {
  int code;
  String msg;
  dynamic data;

  Result({required this.code, required this.msg, required this.data});

  factory Result.fromJson(Map<String, dynamic> json) =>
      Result(code: json["code"], msg: json["msg"], data: json["data"]);
}

// 分页响应结果
class PageRes {
  int pages;
  int total;
  List<dynamic> list;

  PageRes({required this.pages, required this.total, required this.list});

  factory PageRes.fromJson(Map<String, dynamic> json) =>
      PageRes(pages: json['pages'], total: json['total'], list: json['list']);
}

// 二维码类型
enum QrCodeType {
  person(type: 0, desc: '个人二维码');

  final int type;
  final String desc;

  const QrCodeType({required this.type, required this.desc});
}

// 二维码数据
class QrCodeData {
  // 类型：个人二维码等等，后续可扩展
  final int type;
  // 数据(json格式)
  final String data;

  QrCodeData({required this.type, required this.data});

  factory QrCodeData.fromJson(Map<String, dynamic> json) =>
      QrCodeData(type: json['type'], data: json['data']);

  Map<String, dynamic> toJson() => {'type': type, 'data': data};
}
