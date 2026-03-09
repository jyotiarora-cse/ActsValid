// lib/core/constants/api_constants.dart

class ApiConstants {
  // Base URL — baad mein real URL lagana
  static const String baseUrl = 'https://api.actsvalid.com';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Document Endpoints
  static const String documents = '/documents';
  static const String documentRequest = '/documents/request';

  // Rates Endpoints
  static const String rates = '/rates';

  // User Endpoints
  static const String updateProfile = '/users/me';
  static const String notifications = '/users/me/notifications';
  static const String deleteRequest = '/users/me/delete-request';
  static const String registerDevice = '/devices/register';
}