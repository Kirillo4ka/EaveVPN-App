import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:http/http.dart' as http;

class EaveVpnSync {
  static const String secretKeyStr = 'eavevpn_secure_master_token_key_2026_x77!';
  static const String configUrl =
      'https://raw.githubusercontent.com/Kirillo4ka/configs-EaveVPN-app/main/eavevpn_servers.enc';

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

  static Future<bool> syncConfigs({bool force = false}) async {
    try {
      final response = await http.get(
        Uri.parse(configUrl),
        headers: {
          'Authorization': 'token $_token',
          'User-Agent': 'EaveVPN-Client/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return false;
      }

      final decryptedContent = decryptEncryptedConfig(response.bodyBytes);
      if (decryptedContent.trim().isEmpty) {
        return false;
      }

      // Convert raw nodes into Clash YAML
      final lines = decryptedContent
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !e.startsWith('#'))
          .toList();
      final clashYaml = convertProxyUrisToMihomoYaml(lines);
      if (clashYaml.trim().isEmpty) {
        return false;
      }

      final ref = globalState.container;
      final profiles = ref.read(profilesProvider);
      Profile? eaveProfile;
      for (final p in profiles) {
        if (p.label == 'EaveVPN Official') {
          eaveProfile = p;
          break;
        }
      }

      final yamlBytes = Uint8List.fromList(utf8.encode(clashYaml));

      if (eaveProfile == null) {
        // Create new profile
        final baseProfile = Profile.normal(
          label: 'EaveVPN Official',
          url: configUrl,
        );
        final savedProfile = await baseProfile.saveFile(yamlBytes);
        ref.read(profilesProvider.notifier).put(savedProfile);
        ref.read(currentProfileIdProvider.notifier).value = savedProfile.id;
        ref.read(setupActionProvider.notifier).applyProfileDebounce();
      } else {
        // Update existing profile file
        final updatedProfile = await eaveProfile.saveFile(yamlBytes);
        ref.read(profilesProvider.notifier).put(updatedProfile);
        if (ref.read(currentProfileIdProvider) == eaveProfile.id) {
          ref.read(setupActionProvider.notifier).applyProfileDebounce(silence: true);
        } else {
          ref.read(currentProfileIdProvider.notifier).value = eaveProfile.id;
          ref.read(setupActionProvider.notifier).applyProfileDebounce();
        }
      }

      return true;
    } catch (e) {
      commonPrint.log('EaveVpnSync error: $e');
      return false;
    }
  }
}
