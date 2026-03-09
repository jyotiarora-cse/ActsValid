// lib/features/documents/data/document_repository.dart

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import 'document_model.dart';

class DocumentRepository {
  final Dio _dio;

  DocumentRepository({required Dio dio}) : _dio = dio;

  // FR-DOC-01: Document Request Submit karo
  // POST /documents/request
  Future<String> submitRequest(DocumentRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.documentRequest,
        data: request.toJson(),
      );
      // request_id return karo
      return response.data['request_id'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Documents List lao — History ke liye
  // GET /documents
  Future<List<DocumentResponse>> getDocuments({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.documents,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final List data = response.data['documents'];
      return data.map((e) => DocumentResponse.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Single Document Detail lao
  // GET /documents/:id
  Future<DocumentResponse> getDocument(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.documents}/$id');
      return DocumentResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handle karo
  String _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request. Form check karo';
      case 401:
        return 'Session expire ho gayi. Dobara login karo';
      case 429:
        return 'Bahut zyada requests. Thoda wait karo';
      case 500:
        return 'Server error. Baad mein try karo';
      default:
        return 'Kuch gadbad hui. Dobara try karo';
    }
  }
}