import 'package:dio/dio.dart';

/// Backend environments. Switch [HttpClient.environment] to point the whole app
/// at one or the other.
enum ApiEnvironment {
  development('http://192.168.20.13:3000'),
  production('https://crawllertcg.uponpenguin.com');

  const ApiEnvironment(this.baseUrl);
  final String baseUrl;
}

class HttpClient {
  /// Active environment. Change to [ApiEnvironment.production] before release.
  /// Note: on Android emulator use http://10.0.2.2:3000 instead of localhost.
  static const ApiEnvironment environment = ApiEnvironment.production;

  static HttpClient? _instance;
  late final Dio _dio;

  HttpClient._() {
    print(environment.baseUrl);
    _dio = Dio(
      BaseOptions(
        baseUrl: environment.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  static HttpClient get instance {
    _instance ??= HttpClient._();
    return _instance!;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
