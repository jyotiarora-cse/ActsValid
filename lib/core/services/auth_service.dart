// lib/core/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/api_constants.dart';
import 'token_service.dart';

class AuthService {
  final Dio _dio;
  final TokenService _tokenService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthService({
    required Dio dio,
    required TokenService tokenService,
  })  : _dio = dio,
        _tokenService = tokenService;

  // FR-AUTH-01: Email/Password Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      // FR-AUTH-05: Real tokens secure storage mein save karo
      await _tokenService.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );

      return response.data['user'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FR-AUTH-01: Biometric Verify
  // (tumhara existing biometric code yahan aaya)
  Future<bool> verifyBiometric() async {
    try {
      bool isSupported = await _localAuth.isDeviceSupported();
      bool canCheck = await _localAuth.canCheckBiometrics;

      if (!isSupported || !canCheck) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to login to ActsValid',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Current User Info — GET /auth/me
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FR-AUTH-04: Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      await _dio.post(
        ApiConstants.logout,
        data: {'refresh_token': refreshToken},
      );
    } catch (_) {
      // Server error aaye toh bhi local logout karo
    } finally {
      // FR-AUTH-04: Local tokens clear karo
      await _tokenService.clearTokens();
    }
  }

  // Error Messages Hindi mein 😊
  String _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Email ya password galat hai';
      case 429:
        return 'Bahut zyada attempts. Thoda wait karo';
      case 500:
        return 'Server error. Baad mein try karo';
      default:
        return 'Kuch gadbad hui. Dobara try karo';
    }
  }
}