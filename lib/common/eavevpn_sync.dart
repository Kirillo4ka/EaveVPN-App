import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:http/http.dart' as http;

class EaveVpnSync {
  static const String secretKeyStr = 'eavevpn_secure_master_token_key_2026_x77!';
  static const String vpnUrl =
      'https://raw.githubusercontent.com/Kirillo4ka/eavevpn-automation/main/BLACK_SS+All.txt';
  static const String unblockUrl =
      'https://raw.githubusercontent.com/Kirillo4ka/eavevpn-automation/main/WHITE-CIDR-all.txt';

  // Obfuscated GitHub Token for private config repository access
  static final List<int> _tokenBytes = [
    103, 104, 112, 95, 71, 66, 83, 56, 108, 83, 105, 65, 108, 55, 52, 105, 107,
    78, 65, 102, 122, 110, 105, 104, 111, 81, 65, 71, 57, 90, 76, 79, 87, 71, 48,
    90, 101, 54, 90, 54,
  ];

  static String get _token => utf8.decode(_tokenBytes);

  static Uint8List _getMasterKey() {
    return Uint8List.fromList(sha256.convert(utf8.encode(secretKeyStr)).bytes);
  }

  static String decryptEncryptedConfig(Uint8List encryptedBytes) {
    if (encryptedBytes.length < 32) {
      throw Exception('Invalid encrypted payload length');
    }

    final key = _getMasterKey();
    final iv = encryptedBytes.sublist(0, 16);
    final tag = encryptedBytes.sublist(16, 32);
    final cipherBytes = encryptedBytes.sublist(32);

    // Verify tag
    final checkData = Uint8List.fromList([...key, ...iv, ...cipherBytes]);
    final expectedTag = Uint8List.fromList(
      sha256.convert(checkData).bytes.sublist(0, 16),
    );

    for (int i = 0; i < 16; i++) {
      if (tag[i] != expectedTag[i]) {
        throw Exception('Checksum verification failed');
      }
    }

    // Generate Keystream
    final keyStream = <int>[];
    int counter = 0;
    while (keyStream.length < cipherBytes.length) {
      final counterBytes = ByteData(4)..setUint32(0, counter, Endian.big);
      final blockInput = Uint8List.fromList([
        ...key,
        ...iv,
        ...counterBytes.buffer.asUint8List(),
      ]);
      final block = sha256.convert(blockInput).bytes;
      keyStream.addAll(block);
      counter++;
    }

    final decryptedBytes = Uint8List(cipherBytes.length);
    for (int i = 0; i < cipherBytes.length; i++) {
      decryptedBytes[i] = cipherBytes[i] ^ keyStream[i];
    }

    return utf8.decode(decryptedBytes);
  }

  static Future<Profile?> _syncSingleProfile({
    required String label,
    required String url,
    bool selectIfNone = false,
    bool filter4gOnly = false,
    bool filterCountryOnly = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $_token',
          'User-Agent': 'EaveVPN-Client/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      String decryptedContent = '';
      if (url.endsWith('.enc')) {
        decryptedContent = decryptEncryptedConfig(response.bodyBytes);
      } else {
        decryptedContent = utf8.decode(response.bodyBytes, allowMalformed: true);
        if (!decryptedContent.contains('://')) {
          try {
            decryptedContent = decryptEncryptedConfig(response.bodyBytes);
          } catch (_) {}
        }
      }

      if (decryptedContent.trim().isEmpty) {
        return null;
      }

      final lines = decryptedContent
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !e.startsWith('#'))
          .toList();
      final clashYaml = convertProxyUrisToMihomoYaml(
        lines,
        groupName: label,
        isUnblockMode: label == 'Обход блокировок',
        filter4gOnly: filter4gOnly,
        filterCountryOnly: filterCountryOnly,
      );
      if (clashYaml.trim().isEmpty) {
        return null;
      }

      final ref = globalState.container;
      final profiles = ref.read(profilesProvider);
      Profile? existingProfile;
      for (final p in profiles) {
        if (p.label == label) {
          existingProfile = p;
          break;
        }
      }

      final yamlBytes = Uint8List.fromList(utf8.encode(clashYaml));
      Profile finalProfile;
      if (existingProfile == null) {
        final baseProfile = Profile.normal(label: label, url: url);
        finalProfile = await baseProfile.saveFile(yamlBytes);
        ref.read(profilesProvider.notifier).put(finalProfile);
      } else {
        finalProfile = await existingProfile.saveFile(yamlBytes);
        ref.read(profilesProvider.notifier).put(finalProfile);
      }

      final currentId = ref.read(currentProfileIdProvider);
      if (currentId == null || selectIfNone) {
        if (currentId != finalProfile.id) {
          ref.read(currentProfileIdProvider.notifier).value = finalProfile.id;
          ref.read(setupActionProvider.notifier).applyProfileDebounce();
        }
      } else if (currentId == finalProfile.id) {
        ref.read(setupActionProvider.notifier).applyProfileDebounce(silence: true);
      }

      return finalProfile;
    } catch (e) {
      commonPrint.log('EaveVpnSync error for $label: $e');
      return null;
    }
  }

  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<DateTime?> lastSyncNotifier = ValueNotifier<DateTime?>(null);
  static Timer? _hourlyTimer;

  static Future<void> initLastSync() async {
    final saved = await Preferences().getLastSyncTime();
    if (saved != null && lastSyncNotifier.value == null) {
      lastSyncNotifier.value = saved;
    }
  }

  static void startHourlySync() {
    _hourlyTimer?.cancel();
    _hourlyTimer = Timer.periodic(const Duration(hours: 1), (_) {
      commonPrint.log('EaveVpnSync: running hourly auto-sync...');
      syncConfigs(force: true);
    });
  }

  static String getLastSyncText() {
    final last = lastSyncNotifier.value;
    if (last == null) return 'Обновление раз в 1 час';
    final h = last.hour.toString().padLeft(2, '0');
    final m = last.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    if (now.year == last.year && now.month == last.month && now.day == last.day) {
      return 'Обновлено в $h:$m';
    }
    final d = last.day.toString().padLeft(2, '0');
    final mo = last.month.toString().padLeft(2, '0');
    return 'Обновлено $d.$mo в $h:$m';
  }

  static Future<bool> syncConfigs({bool force = false}) async {
    if (isSyncingNotifier.value) return false;
    isSyncingNotifier.value = true;
    try {
      final ref = globalState.container;
      final currentId = ref.read(currentProfileIdProvider);
      final hasActive = currentId != null;

      final isDesktop = system.isDesktop;

      // 1. Sync VPN Profile (All configs on Desktop; only countries on Android)
      final vpnProfile = await _syncSingleProfile(
        label: 'VPN',
        url: vpnUrl,
        selectIfNone: !hasActive,
        filterCountryOnly: !isDesktop,
      );

      // 2. Sync Unblock Profile (Only on mobile / Android; only 4G/LTE servers)
      Profile? unblockProfile;
      if (!isDesktop) {
        unblockProfile = await _syncSingleProfile(
          label: 'Обход блокировок',
          url: unblockUrl,
          selectIfNone: false,
          filter4gOnly: true,
        );
      }

      final now = DateTime.now();
      lastSyncNotifier.value = now;
      Preferences().setLastSyncTime(now);
      startHourlySync();

      return vpnProfile != null || unblockProfile != null;
    } catch (e) {
      commonPrint.log('EaveVpnSync overall error: $e');
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }
}
