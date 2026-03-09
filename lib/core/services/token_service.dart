// lib/core/services/token_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  // FR-AUTH-05: Secure Storage — iOS Keychain + Android Keystore
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Keys — tumhare existing 'jwt_token' key se match karta hai
  static const String _accessTokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Tokens Save Karo
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // Access Token Lao
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Refresh Token Lao
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Sirf Access Token Update Karo (refresh ke baad)
  Future<void> updateAccessToken(String newToken) async {
    await _storage.write(key: _accessTokenKey, value: newToken);
  }

  // Sab Clear Karo (logout pe)
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // JWT se expiry time nikalo
  DateTime? getTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> json = jsonDecode(decoded);

      final exp = json['exp'] as int;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      return null;
    }
  }

  // Token 3 min mein expire hoga? (FR-AUTH-02: 12 min pe refresh)
  bool isTokenExpiringSoon(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return true;
    final refreshTime = expiry.subtract(const Duration(minutes: 3));
    return DateTime.now().isAfter(refreshTime);
  }
}