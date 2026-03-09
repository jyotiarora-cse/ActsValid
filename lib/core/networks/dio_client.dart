// lib/core/networks/dio_client.dart

import 'package:dio/dio.dart';
import '../services/token_service.dart';
import '../constants/api_constants.dart';

class DioClient {
  late final Dio _dio;
  final TokenService _tokenService;
  final Future<void> Function() onLogout;

  DioClient({
    required this.onLogout,
    required TokenService tokenService,
  }) : _tokenService = tokenService {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10), // NFR requirement
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor add karo — auto token refresh
    _dio.interceptors.add(_AuthInterceptor(
      tokenService: _tokenService,
      dio: _dio,
      onLogout: onLogout,
    ));
  }

  Dio get dio => _dio;
}

// ---- Auth Interceptor ----
class _AuthInterceptor extends Interceptor {
  final TokenService tokenService;
  final Dio dio;
  final Future<void> Function() onLogout;
  bool _isRefreshing = false;

  _AuthInterceptor({
    required this.tokenService,
    required this.dio,
    required this.onLogout,
  });

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // Login aur refresh ko token ki zaroorat nahi
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    String? accessToken = await tokenService.getAccessToken();

    // Token expire hone wala hai? Pehle refresh karo
    if (accessToken != null &&
        tokenService.isTokenExpiringSoon(accessToken)) {
      accessToken = await _refreshToken();
    }

    // Har request pe Bearer token lagao (FR-AUTH-03)
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    // 401 aaya — token expire ho gaya
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } else {
        await onLogout();
      }
    }
    handler.next(err);
  }

  // Token Refresh Logic (FR-AUTH-02)
  Future<String?> _refreshToken() async {
    if (_isRefreshing) return null;
    _isRefreshing = true;

    try {
      final refreshToken = await tokenService.getRefreshToken();
      if (refreshToken == null) {
        await onLogout();
        return null;
      }

      // Naya Dio — infinite loop avoid karne ke liye
      final refreshDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
      ));

      final response = await refreshDio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'];
      await tokenService.updateAccessToken(newAccessToken);
      return newAccessToken;
    } catch (e) {
      await onLogout();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}