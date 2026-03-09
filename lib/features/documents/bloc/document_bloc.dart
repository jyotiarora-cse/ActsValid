// lib/features/documents/bloc/document_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/document_repository.dart';
import '../data/document_model.dart';

// ========== EVENTS ==========
abstract class DocumentEvent {}

class SubmitDocumentRequest extends DocumentEvent {
  final DocumentRequest request;
  SubmitDocumentRequest(this.request);
}

class LoadDocuments extends DocumentEvent {}

class LoadDocument extends DocumentEvent {
  final String documentId;
  LoadDocument(this.documentId);
}

class DocumentStatusUpdated extends DocumentEvent {
  final StatusMessage statusMessage;
  DocumentStatusUpdated(this.statusMessage);
}

class RetryDocument extends DocumentEvent {
  final DocumentRequest request;
  RetryDocument(this.request);
}

// ========== STATES ==========
abstract class DocumentState {}

class DocumentInitial extends DocumentState {}
class DocumentLoading extends DocumentState {}

class DocumentRequestSubmitted extends DocumentState {
  final String requestId;
  DocumentRequestSubmitted(this.requestId);
}

class DocumentStatusUpdate extends DocumentState {
  final String documentId;
  final DocumentStatus status;
  final String message;
  final int progressPct;

  DocumentStatusUpdate({
    required this.documentId,
    required this.status,
    required this.message,
    required this.progressPct,
  });
}

class DocumentsLoaded extends DocumentState {
  final List<DocumentResponse> documents;
  DocumentsLoaded(this.documents);
}

class DocumentLoaded extends DocumentState {
  final DocumentResponse document;
  DocumentLoaded(this.document);
}

class DocumentDelivered extends DocumentState {
  final DocumentResponse document;
  DocumentDelivered(this.document);
}

class DocumentError extends DocumentState {
  final String message;
  DocumentError(this.message);
}

// ========== BLOC ==========
class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepository _repository;
  bool _isRequestInFlight = false;

  DocumentBloc({required DocumentRepository repository})
      : _repository = repository,
        super(DocumentInitial()) {
    on<SubmitDocumentRequest>(_onSubmitRequest);
    on<LoadDocuments>(_onLoadDocuments);
    on<LoadDocument>(_onLoadDocument);
    on<DocumentStatusUpdated>(_onStatusUpdated);
    on<RetryDocument>(_onRetryDocument);
  }

  Future<void> _onSubmitRequest(
      SubmitDocumentRequest event,
      Emitter<DocumentState> emit,
      ) async {
    if (_isRequestInFlight) return;
    _isRequestInFlight = true;
    emit(DocumentLoading());
    try {
      final requestId = await _repository.submitRequest(event.request);
      emit(DocumentRequestSubmitted(requestId));
    } catch (e) {
      emit(DocumentError(e.toString()));
    } finally {
      _isRequestInFlight = false;
    }
  }

  Future<void> _onLoadDocuments(
      LoadDocuments event,
      Emitter<DocumentState> emit,
      ) async {
    emit(DocumentLoading());
    try {
      final documents = await _repository.getDocuments();
      emit(DocumentsLoaded(documents));
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> _onLoadDocument(
      LoadDocument event,
      Emitter<DocumentState> emit,
      ) async {
    emit(DocumentLoading());
    try {
      final document = await _repository.getDocument(event.documentId);
      if (document.status == DocumentStatus.delivered) {
        emit(DocumentDelivered(document));
      } else {
        emit(DocumentLoaded(document));
      }
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> _onStatusUpdated(
      DocumentStatusUpdated event,
      Emitter<DocumentState> emit,
      ) async {
    final msg = event.statusMessage;
    emit(DocumentStatusUpdate(
      documentId: msg.documentId,
      status: msg.status,
      message: msg.message,
      progressPct: msg.progressPct,
    ));
    if (msg.status == DocumentStatus.delivered) {
      final document = await _repository.getDocument(msg.documentId);
      emit(DocumentDelivered(document));
    }
  }

  Future<void> _onRetryDocument(
      RetryDocument event,
      Emitter<DocumentState> emit,
      ) async {
    _isRequestInFlight = false;
    add(SubmitDocumentRequest(event.request));
  }
}