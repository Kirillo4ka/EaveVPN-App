import 'dart:io';

import 'error.dart';

String _require(String key) {
  final value = Platform.environment[key];
  if (value == null || value.isEmpty) {
    throw BuildException('Required environment variable not set: $key');
  }
  return value;
}

String _get(String key, {String? defaultValue}) {
  return Platform.environment[key] ?? defaultValue ?? '';
}

class Environment {
  static String get androidNdk {
    final env = Platform.environment['ANDROID_NDK'] ??
        Platform.environment['ANDROID_NDK_HOME'] ??
        Platform.environment['ANDROID_NDK_ROOT'];
    if (env != null && env.isNotEmpty) return env;
    final sdk = Platform.environment['ANDROID_HOME'] ??
        Platform.environment['ANDROID_SDK_ROOT'] ??
        r'D:\DevTools\AndroidSDK';
    final ndkDir = Directory(sdk.endsWith('ndk') ? sdk : sdk + r'\ndk');
    if (ndkDir.existsSync()) {
      final list = ndkDir.listSync().whereType<Directory>().toList();
      if (list.isNotEmpty) {
        list.sort((a, b) => b.path.compareTo(a.path));
        return list.first.path;
      }
    }
    return r'D:\DevTools\AndroidSDK\ndk\28.2.13676358';
  }
  static String get appEnv => _get('APP_ENV', defaultValue: 'pre');
  static String get configuration =>
      _get('BUILDKIT_CONFIGURATION', defaultValue: 'Release').toLowerCase();
  static bool get isDebug => configuration == 'debug';

  static String get hostOs {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'darwin';
    return 'unknown';
  }

  static Future<String> get hostArch async {
    if (Platform.isWindows) {
      return Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'AMD64';
    }
    final result = await Process.run('uname', ['-m']);
    return (result.stdout as String).trim();
  }
}
