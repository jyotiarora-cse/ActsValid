// lib/core/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';
import 'token_service.dart';

enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  error,
}

class WebSocketService {
  final TokenService tokenService;

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _streamController;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  String? _currentDocumentId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  WebSocketService({required this.tokenService});

  // Status getter
  WebSocketStatus get status => _status;

  // Stream of document updates
  Stream<Map<String, dynamic>>? get updates => _streamController?.stream;

  // Connect to WebSocket for a specific document
  Future<void> connect(String documentId) async {
    // Pehle se connected hai toh disconnect karo
    if (_status == WebSocketStatus.connected) {
      await disconnect();
    }

    _currentDocumentId = documentId;
    _streamController = StreamController<Map<String, dynamic>>.broadcast();
    _status = WebSocketStatus.connecting;

    try {
      // Token lo
      final token = await tokenService.getAccessToken();
      if (token == null) {
        _status = WebSocketStatus.error;
        return;
      }

      // WebSocket URL banao
      final wsUrl = Uri.parse(
        '${ApiConstants.wsBase}/documents/$documentId?token=$token',
      );

      // Connect karo
      _channel = WebSocketChannel.connect(wsUrl);
      _status = WebSocketStatus.connected;
      _reconnectAttempts = 0;

      // Messages sunna shuru karo
      _channel!.stream.listen(
            (message) => _onMessage(message),
        onError: (error) => _onError(error),
        onDone: () => _onDone(),
        cancelOnError: false,
      );
    } catch (e) {
      _status = WebSocketStatus.error;
      _scheduleReconnect();
    }
  }

  // Message aaya
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      _streamController?.add(data);
    } catch (e) {
      // Invalid JSON — ignore
    }
  }

  // Error aaya
  void _onError(dynamic error) {
    _status = WebSocketStatus.error;
    _scheduleReconnect();
  }

  // Connection band ho gayi
  void _onDone() {
    _status = WebSocketStatus.disconnected;
    // Agar document complete nahi hua toh reconnect karo
    _scheduleReconnect();
  }

  // Auto reconnect
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    if (_currentDocumentId == null) return;

    _reconnectAttempts++;

    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final delay = Duration(seconds: 2 * _reconnectAttempts);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_currentDocumentId != null) {
        connect(_currentDocumentId!);
      }
    });
  }

  // Disconnect karo
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _currentDocumentId = null;
    _reconnectAttempts = 0;

    await _channel?.sink.close();
    _channel = null;

    await _streamController?.close();
    _streamController = null;

    _status = WebSocketStatus.disconnected;
  }
}