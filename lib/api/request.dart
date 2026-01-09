// 请求工具类
import 'package:dio/dio.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/constants/global.dart';
import 'package:zchat/model/result.dart';
import 'package:zchat/stores/token.dart';

class DioRequest {
  final _dio = Dio();

  DioRequest() {
    // 设置基础地址和超时时间
    _dio.options.baseUrl = GlobalConstants.baseUrl;
    _dio.options.sendTimeout = Duration(seconds: GlobalConstants.timeout);
    _dio.options.receiveTimeout = Duration(seconds: GlobalConstants.timeout);

    // 添加拦截器
    _addInterceptors();
  }

  // 添加拦截器
  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          final token = tokenManager.getToken();
          // 往请求头中写入token
          if (token.isNotEmpty) {
            request.headers['token'] = token;
          }
          handler.next(request);
        },
        onResponse: (response, handler) {
          // 响应成功
          if (response.statusCode! >= 200 && response.statusCode! < 300) {
            handler.next(response);
            return;
          }
          // 响应失败
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              message: response.data['msg'] ?? '请求失败',
            ),
          );
        },
        onError: (error, handler) {
          print('error: ${error.response?.data}');
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              message: error.response?.data['msg'] ?? '请求失败',
            ),
          );
        },
      ),
    );
  }

  // get请求
  Future<dynamic> get(String url, {Map<String, dynamic>? params}) {
    return _handleResponse(_dio.get(url, queryParameters: params));
  }

  // post请求
  Future<dynamic> post(String url, {Map<String, dynamic>? data}) {
    return _handleResponse(_dio.post(url, data: data));
  }

  // 处理响应结果
  Future<dynamic> _handleResponse(
    Future<Response<dynamic>> task,
  ) async {
    try {
      final res = await task;
      final result = Result.fromJson(res.data);
      // 判断业务状态吗是否成功
      if (result.code == GlobalConstants.successCode) {
        return result.data;
      }
      throw DioException(
        requestOptions: res.requestOptions,
        message: result.msg,
      );
    } catch (e) {
      print('_handleResponse, error: $e');
      // 请求错误提示
      ToastUtils.showGlobalToast(
        msg: (e as DioException).message ?? '请求失败',
        duration: Duration(seconds: 1),
      );
      rethrow;
    }
  }
}

final request = DioRequest();
