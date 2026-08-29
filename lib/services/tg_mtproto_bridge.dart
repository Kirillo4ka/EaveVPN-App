import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class TgMtprotoBridge {
  static Process? _process;
  static bool _isRunning = false;
  static int _port = 1443;
  static String _secret = 'b86fd5a64123a081a8eed2b9bbda13ae';
  static String _workerDomain = 'eave-tg.fastedge.workers.dev';
  static final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);

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

    _isRunning = true;
    isRunningNotifier.value = true;
    return true;
  }

  static Future<void> stop() async {
    _isRunning = false;
    isRunningNotifier.value = false;
    try {
      _process?.kill(ProcessSignal.sigterm);
      _process = null;
      if (Platform.isWindows) {
        Process.run('taskkill', ['/F', '/IM', 'tg-ws-proxy.exe', '/T']);
      }
      debugPrint('[TgMtprotoBridge] Stopped tg-ws-proxy');
    } catch (_) {}
  }
}
