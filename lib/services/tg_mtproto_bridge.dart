import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

// --- Pure Dart AES-256-CTR Implementation ---
class _DartAesCtr {
  final Uint8Array32 key;
  final Uint8List iv;
  final Uint8List counter = Uint8List(16);
  final Uint8List keystream = Uint8List(16);
  int keystreamPos = 16;
  final Uint32List w = Uint32List(60);

  _DartAesCtr(Uint8List keyBytes, Uint8List ivBytes)
      : key = Uint8Array32.fromList(keyBytes),
        iv = Uint8List.fromList(ivBytes) {
    counter.setAll(0, iv);
    _initKey();
  }

  void _initKey() {
    for (var i = 0; i < 8; i++) {
      w[i] = (key[i * 4] << 24) |
          (key[i * 4 + 1] << 16) |
          (key[i * 4 + 2] << 8) |
          key[i * 4 + 3];
    }
    const rcon = [
      0x01000000, 0x02000000, 0x04000000, 0x08000000,
      0x10000000, 0x20000000, 0x40000000, 0x80000000,
      0x1B000000, 0x36000000,
    ];
    for (var i = 8; i < 60; i++) {
      var temp = w[i - 1];
      if (i % 8 == 0) {
        temp = _subWord(_rotWord(temp)) ^ rcon[(i ~/ 8) - 1];
      } else if (i % 8 == 4) {
        temp = _subWord(temp);
      }
      w[i] = w[i - 8] ^ temp;
    }
  }

  int _subWord(int w) {
    return (_sbox[(w >>> 24) & 0xff] << 24) |
        (_sbox[(w >>> 16) & 0xff] << 16) |
        (_sbox[(w >>> 8) & 0xff] << 8) |
        _sbox[w & 0xff];
  }

  int _rotWord(int w) => ((w << 8) | (w >>> 24)) & 0xFFFFFFFF;

  void _encryptBlock(Uint8List blockIn, Uint8List blockOut) {
    var s0 = ((blockIn[0] << 24) | (blockIn[1] << 16) | (blockIn[2] << 8) | blockIn[3]) ^ w[0];
    var s1 = ((blockIn[4] << 24) | (blockIn[5] << 16) | (blockIn[6] << 8) | blockIn[7]) ^ w[1];
    var s2 = ((blockIn[8] << 24) | (blockIn[9] << 16) | (blockIn[10] << 8) | blockIn[11]) ^ w[2];
    var s3 = ((blockIn[12] << 24) | (blockIn[13] << 16) | (blockIn[14] << 8) | blockIn[15]) ^ w[3];

    for (var r = 1; r < 14; r++) {
      final t0 = _te0[(s0 >>> 24) & 0xff] ^ _te1[(s1 >>> 16) & 0xff] ^ _te2[(s2 >>> 8) & 0xff] ^ _te3[s3 & 0xff] ^ w[r * 4];
      final t1 = _te0[(s1 >>> 24) & 0xff] ^ _te1[(s2 >>> 16) & 0xff] ^ _te2[(s3 >>> 8) & 0xff] ^ _te3[s0 & 0xff] ^ w[r * 4 + 1];
      final t2 = _te0[(s2 >>> 24) & 0xff] ^ _te1[(s3 >>> 16) & 0xff] ^ _te2[(s0 >>> 8) & 0xff] ^ _te3[s1 & 0xff] ^ w[r * 4 + 2];
      final t3 = _te0[(s3 >>> 24) & 0xff] ^ _te1[(s0 >>> 16) & 0xff] ^ _te2[(s1 >>> 8) & 0xff] ^ _te3[s2 & 0xff] ^ w[r * 4 + 3];
      s0 = t0; s1 = t1; s2 = t2; s3 = t3;
    }

    final t0 = (_sbox[(s0 >>> 24) & 0xff] << 24) | (_sbox[(s1 >>> 16) & 0xff] << 16) | (_sbox[(s2 >>> 8) & 0xff] << 8) | _sbox[s3 & 0xff] ^ w[56];
    final t1 = (_sbox[(s1 >>> 24) & 0xff] << 24) | (_sbox[(s2 >>> 16) & 0xff] << 16) | (_sbox[(s3 >>> 8) & 0xff] << 8) | _sbox[s0 & 0xff] ^ w[57];
    final t2 = (_sbox[(s2 >>> 24) & 0xff] << 24) | (_sbox[(s3 >>> 16) & 0xff] << 16) | (_sbox[(s0 >>> 8) & 0xff] << 8) | _sbox[s1 & 0xff] ^ w[58];
    final t3 = (_sbox[(s3 >>> 24) & 0xff] << 24) | (_sbox[(s0 >>> 16) & 0xff] << 16) | (_sbox[(s1 >>> 8) & 0xff] << 8) | _sbox[s2 & 0xff] ^ w[59];

    blockOut[0] = (t0 >>> 24) & 0xff; blockOut[1] = (t0 >>> 16) & 0xff; blockOut[2] = (t0 >>> 8) & 0xff; blockOut[3] = t0 & 0xff;
    blockOut[4] = (t1 >>> 24) & 0xff; blockOut[5] = (t1 >>> 16) & 0xff; blockOut[6] = (t1 >>> 8) & 0xff; blockOut[7] = t1 & 0xff;
    blockOut[8] = (t2 >>> 24) & 0xff; blockOut[9] = (t2 >>> 16) & 0xff; blockOut[10] = (t2 >>> 8) & 0xff; blockOut[11] = t2 & 0xff;
    blockOut[12] = (t3 >>> 24) & 0xff; blockOut[13] = (t3 >>> 16) & 0xff; blockOut[14] = (t3 >>> 8) & 0xff; blockOut[15] = t3 & 0xff;
  }

  Uint8List process(List<int> data) {
    final out = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      if (keystreamPos == 16) {
        _encryptBlock(counter, keystream);
        keystreamPos = 0;
        for (var j = 15; j >= 0; j--) {
          counter[j] = (counter[j] + 1) & 0xff;
          if (counter[j] != 0) break;
        }
      }
      out[i] = data[i] ^ keystream[keystreamPos++];
    }
    return out;
  }
}

class Uint8Array32 {
  final Uint8List bytes;
  Uint8Array32.fromList(List<int> list) : bytes = Uint8List(32) {
    for (var i = 0; i < min(32, list.length); i++) {
      bytes[i] = list[i];
    }
  }
  int operator [](int index) => bytes[index];
}

final Uint8List _sbox = Uint8List.fromList([
  99,124,119,123,242,107,111,197,48,1,103,43,254,215,171,118,202,130,201,125,250,89,71,240,173,212,162,175,156,164,114,192,183,253,147,38,54,63,247,204,52,165,229,241,113,216,49,21,4,199,35,195,24,150,5,154,7,18,128,226,235,39,178,117,9,131,44,26,27,110,90,160,82,59,214,179,41,227,47,132,83,209,0,237,32,252,177,91,106,203,190,57,74,76,88,207,208,239,176,92,121,159,85,16,126,53,15,133,246,56,211,77,200,10,81,55,142,45,219,84,187,22,138,223,124,86,168,64,80,244,194,220,161,245,40,167,238,225,163,217,58,137,134,34,31,193,127,109,25,189,75,157,143,144,95,196,153,68,231,198,146,145,236,248,152,205,170,140,28,62,78,251,218,224,222,105,249,87,174,180,183,230,155,11,166,61,60,228,141,185,182,120,67,243,186,184,181,188,191,193,221,172,122,233,149,151,158,169,170,234,232,135,136,139,148,65,66,69,70,72,73,79,80,93,94,96,97,98,100,101,102,104,108,112,115,116,129,206,210,213,225,255
]);
final Uint32List _te0 = Uint32List(256), _te1 = Uint32List(256), _te2 = Uint32List(256), _te3 = Uint32List(256);
bool _tablesInitialized = false;
void _initTables() {
  if (_tablesInitialized) return;
  _tablesInitialized = true;
  for (var i = 0; i < 256; i++) {
    final s = _sbox[i];
    final s2 = (s << 1) ^ ((s & 0x80 != 0) ? 0x11b : 0);
    final s3 = s2 ^ s;
    final val = ((s2 << 24) | (s << 16) | (s << 8) | s3) & 0xFFFFFFFF;
    _te0[i] = val;
    _te1[i] = ((val >>> 8) | (val << 24)) & 0xFFFFFFFF;
    _te2[i] = ((val >>> 16) | (val << 16)) & 0xFFFFFFFF;
    _te3[i] = ((val >>> 24) | (val << 8)) & 0xFFFFFFFF;
  }
}

class TgMtprotoBridge {
  static Process? _process;
  static ServerSocket? _serverSocket;
  static bool _isRunning = false;
  static int _port = 1443;
  static final String _secretHex = 'b86fd5a64123a081a8eed2b9bbda13ae';
  static String _workerDomain = 'eave-tg.fastedge.workers.dev';
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

  static Future<bool> start({int port = 1443}) async {
    _initTables();
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

    // Android / macOS / Linux / Native Dart bridge
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
    _DartAesCtr? clientDec;
    _DartAesCtr? clientEnc;
    _DartAesCtr? dcEnc;
    _DartAesCtr? dcDec;
    var isHandshakeDone = false;
    final earlyBuffer = <Uint8List>[];

    final secretBytes = Uint8List.fromList([
      for (var i = 0; i < _secretHex.length; i += 2)
        int.parse(_secretHex.substring(i, i + 2), radix: 16)
    ]);

    clientSocket.listen(
      (data) async {
        if (!isHandshakeDone) {
          if (data.length < 64) {
            earlyBuffer.add(data);
            return;
          }
          isHandshakeDone = true;

          try {
            // 1. Client key derivation
            final keyPart = data.sublist(8, 40);
            final ivPart = data.sublist(40, 56);
            final keyMaterial = Uint8List.fromList([...keyPart, ...secretBytes]);
            final decKey = Uint8List.fromList(sha256.convert(keyMaterial).bytes);
            clientDec = _DartAesCtr(decKey, ivPart);

            final revData = Uint8List.fromList(data.reversed.toList());
            final encKeyMaterial = Uint8List.fromList([...revData.sublist(8, 40), ...secretBytes]);
            final encKey = Uint8List.fromList(sha256.convert(encKeyMaterial).bytes);
            clientEnc = _DartAesCtr(encKey, revData.sublist(40, 56));

            // 2. Decrypt Header & Extract DC
            final decryptedHeader = clientDec!.process(data);
            var dcId = decryptedHeader[60] | (decryptedHeader[61] << 8);
            if (dcId > 32767) dcId -= 65536;

            var targetIp = '149.154.167.220';
            if (dcId.abs() == 1) targetIp = '149.154.175.50';
            if (dcId.abs() == 5) targetIp = '91.108.56.165';

            // 3. Generate Clean DC Relay Header (without proxy secret)
            final rnd = Random.secure();
            final dcHeader = Uint8List(64);
            for (var i = 0; i < 64; i++) {
              dcHeader[i] = rnd.nextInt(256);
            }
            dcHeader[56] = 0xef;
            dcHeader[57] = 0xef;
            dcHeader[58] = 0xef;
            dcHeader[59] = 0xef;
            dcHeader[60] = dcId & 0xff;
            dcHeader[61] = (dcId >> 8) & 0xff;

            final dcKeyPart = dcHeader.sublist(8, 40);
            final dcIvPart = dcHeader.sublist(40, 56);
            final dcEncKey = Uint8List.fromList(sha256.convert(dcKeyPart).bytes);
            dcEnc = _DartAesCtr(dcEncKey, dcIvPart);

            final dcRev = Uint8List.fromList(dcHeader.reversed.toList());
            final dcDecKey = Uint8List.fromList(sha256.convert(dcRev.sublist(8, 40)).bytes);
            dcDec = _DartAesCtr(dcDecKey, dcRev.sublist(40, 56));

            final encryptedDcHeader = dcEnc!.process(dcHeader);
            dcHeader.setRange(56, 64, encryptedDcHeader.sublist(56, 64));

            // 4. Connect to Cloudflare Worker
            final wsUri = 'wss://$_workerDomain/apiws?dst=$targetIp';
            ws = await WebSocket.connect(
              wsUri,
              headers: {
                'User-Agent': 'Mozilla/5.0 (Android; Mobile; rv:128.0) Gecko/128.0 Firefox/128.0',
              },
            ).timeout(const Duration(seconds: 8));

            // Send clean DC header over WebSocket
            ws!.add(dcHeader);

            // Forward incoming data from DC back to Telegram client
            ws!.listen(
              (message) {
                try {
                  List<int> rawBytes = [];
                  if (message is List<int>) {
                    rawBytes = message;
                  } else if (message is Uint8List) {
                    rawBytes = message;
                  }
                  if (rawBytes.isNotEmpty && dcDec != null && clientEnc != null) {
                    final dcPlain = dcDec!.process(rawBytes);
                    final clientCipher = clientEnc!.process(dcPlain);
                    clientSocket.add(clientCipher);
                  }
                } catch (_) {
                  _cleanup(clientSocket, ws);
                }
              },
              onError: (_) => _cleanup(clientSocket, ws),
              onDone: () => _cleanup(clientSocket, ws),
              cancelOnError: true,
            );

            // If extra data in initial message
            if (data.length > 64) {
              final extraPlain = decryptedHeader.sublist(64);
              final extraEnc = dcEnc!.process(extraPlain);
              ws!.add(extraEnc);
            }
          } catch (e) {
            debugPrint('[TgMtprotoBridge] Handshake error: $e');
            _cleanup(clientSocket, ws);
          }
          return;
        }

        // Subsequent messages from Client -> Decrypt -> Re-encrypt -> DC
        if (ws != null && clientDec != null && dcEnc != null) {
          try {
            final plain = clientDec!.process(data);
            final enc = dcEnc!.process(plain);
            ws!.add(enc);
          } catch (_) {
            _cleanup(clientSocket, ws);
          }
        }
      },
      onError: (_) => _cleanup(clientSocket, ws),
      onDone: () => _cleanup(clientSocket, ws),
      cancelOnError: true,
    );
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
        Process.runSync('taskkill', ['/F', '/IM', 'tg-ws-proxy.exe', '/T']);
      }
    } catch (_) {}
    try {
      await _serverSocket?.close();
      _serverSocket = null;
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('[TgMtprotoBridge] Stopped');
  }
}
