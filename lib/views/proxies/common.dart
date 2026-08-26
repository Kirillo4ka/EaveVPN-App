import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/ping_setting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double get listHeaderHeight {
  final measure = globalState.measure;
  return 20 + measure.titleMediumHeight + 4 + measure.bodyMediumHeight + 2;
}

double getItemHeight(ProxyCardType proxyCardType) {
  final measure = globalState.measure;
  final baseHeight =
      16 + measure.bodyMediumHeight * 2 + measure.bodySmallHeight + 8 + 4;
  return switch (proxyCardType) {
    ProxyCardType.expand => baseHeight + measure.labelSmallHeight + 6,
    ProxyCardType.shrink => baseHeight,
    ProxyCardType.min => baseHeight - measure.bodyMediumHeight,
  };
}

List<Group> getCurrentGroups() {
  return globalState.container.read(currentGroupsStateProvider).value;
}

List<Group> getGroups() {
  return globalState.container.read(groupsProvider);
}

void updateCurrentGroupName(String groupName) {
  globalState.container
      .read(proxiesActionProvider.notifier)
      .updateCurrentGroupName(groupName);
}

void updateCurrentUnfoldSet(Set<String> value) {
  globalState.container
      .read(proxiesActionProvider.notifier)
      .updateCurrentUnfoldSet(value);
}

Future<MapEntry<String, int>?> _getProxyHostAndPort(String proxyName, int? profileId) async {
  if (profileId == null) return null;
  try {
    final path = await appPath.getProfilePath(profileId.toString());
    final file = File(path);
    if (!await file.exists()) return null;
    final lines = await file.readAsLines();
    bool inTargetProxy = false;
    String server = '';
    int port = 0;

    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('- name:') || t.startsWith('name:')) {
        var n = t.substring(t.indexOf('name:') + 5).trim();
        if ((n.startsWith('"') && n.endsWith('"')) || (n.startsWith("'") && n.endsWith("'"))) {
          n = n.substring(1, n.length - 1);
        }
        if (n == proxyName || n.contains(proxyName) || proxyName.contains(n)) {
          inTargetProxy = true;
          server = '';
          port = 0;
          continue;
        } else if (inTargetProxy) {
          break;
        }
      }
      if (inTargetProxy) {
        if (t.startsWith('server:')) {
          server = t.substring(7).trim().replaceAll('"', '').replaceAll("'", '');
        } else if (t.startsWith('port:')) {
          port = int.tryParse(t.substring(5).trim().replaceAll('"', '').replaceAll("'", '')) ?? 0;
        }
        if (server.isNotEmpty && port > 0) {
          return MapEntry(server, port);
        }
      }
    }
  } catch (_) {}
  return null;
}

Future<int> _measureTcpPing(String proxyName, int? profileId) async {
  final entry = await _getProxyHostAndPort(proxyName, profileId);
  if (entry == null) return -1;
  try {
    final sw = Stopwatch()..start();
    final socket = await Socket.connect(entry.key, entry.value, timeout: const Duration(seconds: 3));
    sw.stop();
    socket.destroy();
    return sw.elapsedMilliseconds;
  } catch (_) {
    return -1;
  }
}

Future<int> _measureIcmpPing(String proxyName, int? profileId) async {
  final entry = await _getProxyHostAndPort(proxyName, profileId);
  if (entry == null) return -1;
  try {
    if (Platform.isWindows) {
      final res = await Process.run('ping', ['-n', '1', '-w', '2000', entry.key], stdoutEncoding: systemEncoding);
      final out = res.stdout.toString();
      final match = RegExp(r'[=<](\d+)\s*(?:ms|мс|¬б)', caseSensitive: false).firstMatch(out) ??
                    RegExp(r'(?:time|время|ўаҐ¬п)[=<](\d+)', caseSensitive: false).firstMatch(out);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? -1;
      }
    } else {
      final res = await Process.run('ping', ['-c', '1', '-W', '2', entry.key]);
      final out = res.stdout.toString();
      final match = RegExp(r'time=(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(out);
      if (match != null) {
        return double.tryParse(match.group(1)!)?.round() ?? -1;
      }
    }
  } catch (_) {}
  return -1;
}

Future<int> _measureProxyGet(String proxyName, String testUrl) async {
  try {
    final delay = await coreController.getDelay(testUrl, proxyName);
    return delay.value ?? -1;
  } catch (_) {
    return -1;
  }
}

Future<int> _measureProxyHead(String proxyName, String testUrl) async {
  try {
    final headUrl = testUrl.contains('generate_204') ? testUrl : '$testUrl/generate_204';
    final delay = await coreController.getDelay(headUrl, proxyName);
    return delay.value ?? -1;
  } catch (_) {
    return -1;
  }
}

Future<void> proxyDelayTest(Proxy proxy, [String? testUrl]) async {
  final ref = globalState.container;
  final groups = getGroups();
  final currentProfile = ref.read(currentProfileProvider);
  final selectedMap = currentProfile?.selectedMap ?? {};
  final state = computeRealSelectedProxyState(
    proxy.name,
    groups: groups,
    selectedMap: selectedMap,
  );
  final currentTestUrl = state.testUrl.takeFirstValid([
    ref.read(realTestUrlProvider(testUrl)),
  ]);
  if (state.proxyName.isEmpty) {
    return;
  }
  ref
      .read(proxiesActionProvider.notifier)
      .setDelay(Delay(url: currentTestUrl, name: state.proxyName, value: 0));

  final pingType = ref.read(pingTypeProvider);
  int delayValue = -1;

  switch (pingType) {
    case PingType.tcp:
      delayValue = await _measureTcpPing(state.proxyName, currentProfile?.id);
      break;
    case PingType.icmp:
      delayValue = await _measureIcmpPing(state.proxyName, currentProfile?.id);
      break;
    case PingType.proxyGet:
      delayValue = await _measureProxyGet(state.proxyName, currentTestUrl);
      break;
    case PingType.proxyHead:
      delayValue = await _measureProxyHead(state.proxyName, currentTestUrl);
      break;
  }

  ref
      .read(proxiesActionProvider.notifier)
      .setDelay(Delay(url: currentTestUrl, name: state.proxyName, value: delayValue));
}

Future<void> delayTest(List<Proxy> proxies, [String? testUrl]) async {
  final batches = proxies.batch(maxConcurrentDelayTests);
  for (final batch in batches) {
    await Future.wait(
      batch.map((proxy) async {
        await proxyDelayTest(proxy, testUrl);
      }),
    );
  }
  globalState.container.read(sortNumProvider.notifier).add();
}

double getScrollToSelectedOffset({
  required String groupName,
  required List<Proxy> proxies,
  required int columns,
}) {
  final ref = globalState.container;
  final proxyCardType = ref.read(
    proxiesStyleSettingProvider.select((state) => state.cardType),
  );
  final selectedProxyName = ref.read(selectedProxyNameProvider(groupName));
  final findSelectedIndex = proxies.indexWhere(
    (proxy) => proxy.name == selectedProxyName,
  );
  final selectedIndex = findSelectedIndex != -1 ? findSelectedIndex : 0;
  final rows = (selectedIndex / columns).floor();
  return rows * getItemHeight(proxyCardType) + (rows - 1) * 8;
}
