import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service managing the native MTProto -> WebSocket bridge for Telegram (Desktop only)
class TgMtprotoBridge {
  static const int defaultPort = 1443;
  static int _port = defaultPort;
  static const String _secretHex = 'b86fd5a64123a081a8eed2b9bbda13ae';
  static String _workerDomain = 'eave-tg.fastedge.workers.dev';

  static Process? _process;
  static bool _isRunning = false;

  static final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<int> activeConnectionsNotifier = ValueNotifier<int>(0);

  static bool get isRunning => _isRunning;
  static int get port => _port;
  static String get secret => 'dd$_secretHex';
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

  static Future<bool> start({int port = defaultPort}) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      // Mobile platforms use the main VPN mode instead
      return false;
    }

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
        r'D:\EaveVPN\tg-ws-proxy.exe',
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
          Process.runSync('taskkill', ['/F', '/IM', 'TgWsProxy_windows_7_64bit.exe', '/T']);
          await Future.delayed(const Duration(milliseconds: 200));
          debugPrint('[TgMtprotoBridge] Starting $targetExe on port $_port with domain $_workerDomain');
          _process = await Process.start(
            targetExe,
            [
              '--port',
              '$_port',
              '--secret',
              _secretHex,
              '--cfproxy-worker-domain',
              _workerDomain,
              '--dc-ip',
              '1:149.154.175.50',
              '--dc-ip',
              '2:149.154.167.51',
              '--dc-ip',
              '3:149.154.175.100',
              '--dc-ip',
              '4:149.154.167.91',
              '--dc-ip',
              '5:91.108.56.165',
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

    return false;
  }

  static Future<void> stop() async {
    _isRunning = false;
    isRunningNotifier.value = false;
    activeConnectionsNotifier.value = 0;
    try {
      _process?.kill(ProcessSignal.sigterm);
      _process = null;
      if (Platform.isWindows) {
        Process.runSync('taskkill', ['/F', '/IM', 'tg-ws-proxy.exe', '/T']);
        Process.runSync('taskkill', ['/F', '/IM', 'TgWsProxy_windows_7_64bit.exe', '/T']);
      }
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('[TgMtprotoBridge] Stopped');
  }
}
