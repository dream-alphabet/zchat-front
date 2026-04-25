import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zchat/common/toast.dart';
import 'package:zchat/common/constants.dart';
import 'package:zchat/model/common.dart';
import 'package:zchat/routes/index.dart';
import 'package:zchat/stores/token.dart';

// 请求工具类
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
          print('开始请求, url: ${request.uri.path}');
          final token = tokenManager.getToken();
          // 往请求头中写入token
          if (token.isNotEmpty) {
            request.headers['token'] = token;
          }
          print('请求头: ${request.headers}');
          handler.next(request);
        },
        onResponse: (response, handler) {
          // 响应成功
          if (response.statusCode! >= 200 && response.statusCode! < 300) {
            return handler.next(response);
          }
          print('response statusCode: ${response.statusCode}');
          // 响应失败
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              message: response.data['msg'] ?? '请求失败',
            ),
          );
        },
        onError: (error, handler) {
          print('error, statusCode: ${error.response?.statusCode}');
          if (error.response?.statusCode == 401) {
            // 关闭所有页面并跳转到登录页面
            Navigator.pushNamedAndRemoveUntil(
              globalNavigatorKey.currentContext!,
              RoutePath.login,
              (route) => false,
            );
            // 删除本地token
            tokenManager.removeToken();
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                message: '未登录',
              ),
            );
          }
          handler.reject(
            DioException(requestOptions: error.requestOptions, message: '请求失败'),
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
  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? data,
    bool isFormData = false,
  }) {
    return _handleResponse(
      _dio.post(url, data: isFormData ? FormData.fromMap(data ?? {}) : data),
    );
  }

  // 处理响应结果
  Future<dynamic> _handleResponse(Future<Response<dynamic>> task) async {
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
      print('_handleResponse, error: ${(e as DioException).message}');
      // 请求错误提示
      ToastUtils.showGlobalToast(msg: e.message ?? '请求失败');
      rethrow;
    }
  }
}

final request = DioRequest();
