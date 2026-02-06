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
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.5',
      },
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
  String get baseUrl => _dio.options.baseUrl;

  void setBaseUrl(String domain) {
    _dio.options.baseUrl = 'https://$domain';
  }

  /// Set the raw cookie string to be sent with every request
  void setRawCookies(String cookieString) {
    _dio.options.headers['Cookie'] = cookieString;
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
    return _dio.post<String>(path, data: data, options: options);
  }
}
