import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class TgMtprotoBridge {
  static ServerSocket? _server;
  static bool _isRunning = false;
  static int _port = 9090;
  static String _workerUrl = 'wss://eave-tg.fastedge.workers.dev';
  static final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<int> activeConnectionsNotifier = ValueNotifier<int>(0);

  static bool get isRunning => _isRunning;
  static int get port => _port;
  static String get workerUrl => _workerUrl;

  static void setWorkerUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.startsWith('https://')) {
      _workerUrl = 'wss://' + trimmed.substring('https://'.length);
    } else if (trimmed.startsWith('http://')) {
      _workerUrl = 'ws://' + trimmed.substring('http://'.length);
    } else if (!trimmed.startsWith('ws://') && !trimmed.startsWith('wss://')) {
      _workerUrl = 'wss://' + trimmed;
    } else {
      _workerUrl = trimmed;
    }
  }

  static Future<bool> start({int port = 9090}) async {
    if (_isRunning) {
      if (_port == port) return true;
      await stop();
    }

    _port = port;
    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
      _isRunning = true;
      isRunningNotifier.value = true;
      debugPrint('[TgMtprotoBridge] Started on 127.0.0.1:$_port -> $_workerUrl');

      _server!.listen(_handleIncomingClient, onError: (err) {
        debugPrint('[TgMtprotoBridge] Server error: $err');
      });

      return true;
    } catch (e) {
      debugPrint('[TgMtprotoBridge] Failed to start on port $_port: $e');
      _isRunning = false;
      isRunningNotifier.value = false;
      return false;
    }
  }

  static Future<void> stop() async {
    _isRunning = false;
    isRunningNotifier.value = false;
    activeConnectionsNotifier.value = 0;
    try {
      await _server?.close();
      _server = null;
      debugPrint('[TgMtprotoBridge] Stopped');
    } catch (_) {}
  }

  static void _handleIncomingClient(Socket clientSocket) async {
    activeConnectionsNotifier.value++;
    WebSocket? ws;

    try {
      ws = await WebSocket.connect(
        _workerUrl,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      // Client TCP -> WebSocket
      clientSocket.listen(
        (data) {
          try {
            ws?.add(data);
          } catch (_) {
            _cleanup(clientSocket, ws);
          }
        },
        onError: (_) => _cleanup(clientSocket, ws),
        onDone: () => _cleanup(clientSocket, ws),
        cancelOnError: true,
      );

      // WebSocket -> Client TCP
      ws.listen(
        (message) {
          try {
            if (message is List<int>) {
              clientSocket.add(message);
            } else if (message is Uint8List) {
              clientSocket.add(message);
            } else if (message is String) {
              clientSocket.write(message);
            }
          } catch (_) {
            _cleanup(clientSocket, ws);
          }
        },
        onError: (_) => _cleanup(clientSocket, ws),
        onDone: () => _cleanup(clientSocket, ws),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[TgMtprotoBridge] Connection error: \$e');
      _cleanup(clientSocket, ws);
    }
  }

  static void _cleanup(Socket clientSocket, WebSocket? ws) {
    try {
      clientSocket.destroy();
    } catch (_) {}
    try {
      ws?.close();
    } catch (_) {}
    if (activeConnectionsNotifier.value > 0) {
      activeConnectionsNotifier.value--;
    }
  }
}
