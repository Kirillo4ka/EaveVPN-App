import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class TgMtprotoBridge {
  static Process? _process;
  static ServerSocket? _serverSocket;
  static bool _isRunning = false;
  static int _port = 1443;
  static String _secret = 'b86fd5a64123a081a8eed2b9bbda13ae';
  static String _workerDomain = 'eave-tg.fastedge.workers.dev';
  static final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<int> activeConnectionsNotifier = ValueNotifier<int>(0);

  static bool get isRunning => _isRunning;
  static int get port => _port;
  static String get secret => 'dd' + _secret;
  static String get workerDomain => _workerDomain;

  static void setWorkerDomain(String domain) {
    var trimmed = domain.trim();
    if (trimmed.startsWith('https://')) {
      trimmed = trimmed.substring('https://'.length);
    } else if (trimmed.startsWith('http://')) {
      trimmed = trimmed.substring('http://'.length);
    }
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _workerDomain = trimmed;
  }

  static Future<bool> start({int port = 1443}) async {
    if (_isRunning) {
      if (_port == port) return true;
      await stop();
    }

    _port = port;

    if (Platform.isWindows) {
      final appDir = File(Platform.resolvedExecutable).parent.path;
      final exeCandidates = [
        '$appDir\\tg-ws-proxy.exe',
        r'D:\DevTools\EaveVPN-Build\tg-ws-proxy-repo\dist\tg-ws-proxy.exe',
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\EaveVPN\\tg-ws-proxy.exe',
      ];

      String? targetExe;
      for (final candidate in exeCandidates) {
        if (File(candidate).existsSync()) {
          targetExe = candidate;
          break;
        }
      }

      if (targetExe != null) {
        try {
          Process.runSync('taskkill', ['/F', '/IM', 'tg-ws-proxy.exe', '/T']);
          debugPrint('[TgMtprotoBridge] Starting $targetExe on port $_port with domain $_workerDomain');
          _process = await Process.start(
            targetExe,
            [
              '--port',
              '$_port',
              '--secret',
              _secret,
              '--cfproxy-worker-domain',
              _workerDomain,
              '--dc-ip',
              '2:149.154.167.220',
              '--dc-ip',
              '4:149.154.167.220',
            ],
            mode: ProcessStartMode.detached,
          );
          _isRunning = true;
          isRunningNotifier.value = true;
          return true;
        } catch (e) {
          debugPrint('[TgMtprotoBridge] Failed to start tg-ws-proxy.exe: $e');
        }
      }
    }

    // Android / macOS / Linux / Pure Dart fallback
    return await _startDartBridge();
  }

  static Future<bool> _startDartBridge() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
      _isRunning = true;
      isRunningNotifier.value = true;
      debugPrint('[TgMtprotoBridge] Native Dart bridge started on 127.0.0.1:$_port');

      _serverSocket!.listen(_handleDartClient, onError: (err) {
        debugPrint('[TgMtprotoBridge] Server error: $err');
      });
      return true;
    } catch (e) {
      debugPrint('[TgMtprotoBridge] Dart bridge start failed: $e');
      _isRunning = false;
      isRunningNotifier.value = false;
      return false;
    }
  }

  static void _handleDartClient(Socket clientSocket) {
    activeConnectionsNotifier.value++;
    WebSocket? ws;
    final earlyBuffer = <Uint8List>[];
    var wsConnected = false;

    clientSocket.listen(
      (data) {
        if (wsConnected && ws != null) {
          try {
            ws!.add(data);
          } catch (_) {
            _cleanup(clientSocket, ws);
          }
        } else {
          earlyBuffer.add(data);
        }
      },
      onError: (_) => _cleanup(clientSocket, ws),
      onDone: () => _cleanup(clientSocket, ws),
      cancelOnError: true,
    );

    final wsUri = 'wss://$_workerDomain/apiws?dst=149.154.167.220';
    WebSocket.connect(
      wsUri,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Android; Mobile; rv:128.0) Gecko/128.0 Firefox/128.0',
      },
    ).timeout(const Duration(seconds: 10)).then((connectedWs) {
      ws = connectedWs;
      wsConnected = true;

      for (final packet in earlyBuffer) {
        try {
          ws!.add(packet);
        } catch (_) {}
      }
      earlyBuffer.clear();

      ws!.listen(
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
    }).catchError((e) {
      debugPrint('[TgMtprotoBridge] Dart WS connect error: $e');
      _cleanup(clientSocket, ws);
    });
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

  static Future<void> stop() async {
    _isRunning = false;
    isRunningNotifier.value = false;
    activeConnectionsNotifier.value = 0;
    try {
      _process?.kill(ProcessSignal.sigterm);
      _process = null;
      if (Platform.isWindows) {
        Process.run('taskkill', ['/F', '/IM', 'tg-ws-proxy.exe', '/T']);
      }
    } catch (_) {}
    try {
      await _serverSocket?.close();
      _serverSocket = null;
    } catch (_) {}
    debugPrint('[TgMtprotoBridge] Stopped');
  }
}
