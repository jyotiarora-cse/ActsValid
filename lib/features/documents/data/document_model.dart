// lib/features/documents/data/document_model.dart

class DocumentRequest {
  final String documentType;
  final String jurisdiction;
  final String transactionType;
  final double transactionValue;
  final String propertyAddress;
  final String supplementaryText;

  DocumentRequest({
    required this.documentType,
    required this.jurisdiction,
    required this.transactionType,
    required this.transactionValue,
    required this.propertyAddress,
    required this.supplementaryText,
  });

  // API ke liye JSON banao
  Map<String, dynamic> toJson() {
    return {
      'document_type': documentType,
      'jurisdiction': jurisdiction,
      'transaction_type': transactionType,
      'transaction_value': transactionValue,
      'property_address': propertyAddress,
      'supplementary_text': supplementaryText,
    };
  }
}

// Document Status — WebSocket se aata hai
enum DocumentStatus {
  pending,
  assemblingContext,
  generating,
  signing,
  delivered,
  failed,
}

// Document Response — API se aata hai
class DocumentResponse {
  final String id;
  final String documentType;
  final String jurisdiction;
  final DocumentStatus status;
  final String? ipfsCid;
  final String? downloadUrl;
  final DateTime createdAt;

  DocumentResponse({
    required this.id,
    required this.documentType,
    required this.jurisdiction,
    required this.status,
    this.ipfsCid,
    this.downloadUrl,
    required this.createdAt,
  });

  factory DocumentResponse.fromJson(Map<String, dynamic> json) {
    return DocumentResponse(
      id: json['id'],
      documentType: json['document_type'],
      jurisdiction: json['jurisdiction'],
      status: _parseStatus(json['status']),
      ipfsCid: json['ipfs_cid'],
      downloadUrl: json['download_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static DocumentStatus _parseStatus(String status) {
    switch (status) {
      case 'PENDING':
        return DocumentStatus.pending;
      case 'ASSEMBLING_CONTEXT':
        return DocumentStatus.assemblingContext;
      case 'GENERATING':
        return DocumentStatus.generating;
      case 'SIGNING':
        return DocumentStatus.signing;
      case 'DELIVERED':
        return DocumentStatus.delivered;
      case 'FAILED':
        return DocumentStatus.failed;
      default:
        return DocumentStatus.pending;
    }
  }
}

// WebSocket Status Message
class StatusMessage {
  final String documentId;
  final DocumentStatus status;
  final String message;
  final int progressPct;

  StatusMessage({
    required this.documentId,
    required this.status,
    required this.message,
    required this.progressPct,
  });

  factory StatusMessage.fromJson(Map<String, dynamic> json) {
    return StatusMessage(
      documentId: json['document_id'],
      status: DocumentResponse._parseStatus(json['status']),
      message: json['message'],
      progressPct: json['progress_pct'],
    );
  }
}