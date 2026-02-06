import 'package:dio/dio.dart';

class AppHttpClient {
  late final Dio _dio;

  AppHttpClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      followRedirects: true,
      maxRedirects: 10,
      validateStatus: (status) => status != null && status < 400,
    ));
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: false,
      responseHeader: true,
      responseBody: false,
      error: true,
      logPrint: (o) => print('[Dio] $o'),
    ));
  }

  Dio get dio => _dio;

  void setBaseUrl(String domain) {
    _dio.options.baseUrl = 'https://$domain';
    print('[HttpClient] baseUrl set to: https://$domain');
  }

  /// Set the raw cookie string to be sent with every request
  void setRawCookies(String cookieString) {
    _dio.options.headers['Cookie'] = cookieString;
    print('[HttpClient] cookies set (${cookieString.length} chars): ${cookieString.substring(0, cookieString.length.clamp(0, 80))}...');
  }

  /// Append a cookie (name=value) to the existing cookie header
  void appendCookie(String cookie) {
    final existing = _dio.options.headers['Cookie'] as String? ?? '';
    if (existing.isNotEmpty) {
      _dio.options.headers['Cookie'] = '$existing; $cookie';
    } else {
      _dio.options.headers['Cookie'] = cookie;
    }
  }

  Future<Response<String>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    return _dio.get<String>(
      path,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
  }

  Future<Response<String>> post(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    final response = await _dio.post<String>(path, data: data, options: options);
    final body = response.data ?? '';
    final preview = body.length > 500 ? body.substring(0, 500) : body;
    print('[HttpClient] POST $path → ${response.statusCode}, body preview: $preview');
    return response;
  }
}
