import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloseConnectionsItem extends ConsumerWidget {
  const CloseConnectionsItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final appLocalizations = context.appLocalizations;
    final closeConnections = ref.watch(
      appSettingProvider.select((state) => state.closeConnections),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.autoCloseConnections),
      subtitle: Text(appLocalizations.autoCloseConnectionsDesc),
      value: closeConnections,
      onChanged: (value) async {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(closeConnections: value));
      },
    );
  }
}

class UsageItem extends ConsumerWidget {
  const UsageItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final appLocalizations = context.appLocalizations;
    final onlyStatisticsProxy = ref.watch(
      appSettingProvider.select((state) => state.onlyStatisticsProxy),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.onlyStatisticsProxy),
      subtitle: Text(appLocalizations.onlyStatisticsProxyDesc),
      value: onlyStatisticsProxy,
      onChanged: (bool value) async {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(onlyStatisticsProxy: value));
      },
    );
  }
}

class MinimizeItem extends ConsumerWidget {
  const MinimizeItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final minimizeOnExit = ref.watch(
      appSettingProvider.select((state) => state.minimizeOnExit),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.minimizeOnExit),
      subtitle: Text(appLocalizations.minimizeOnExitDesc),
      value: minimizeOnExit,
      onChanged: (bool value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(minimizeOnExit: value));
      },
    );
  }
}

class AutoLaunchItem extends ConsumerWidget {
  const AutoLaunchItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final autoLaunch = ref.watch(
      appSettingProvider.select((state) => state.autoLaunch),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.autoLaunch),
      subtitle: Text(appLocalizations.autoLaunchDesc),
      value: autoLaunch,
      onChanged: (bool value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(autoLaunch: value));
      },
    );
  }
}

class SilentLaunchItem extends ConsumerWidget {
  const SilentLaunchItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final silentLaunch = ref.watch(
      appSettingProvider.select((state) => state.silentLaunch),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.silentLaunch),
      subtitle: Text(appLocalizations.silentLaunchDesc),
      value: silentLaunch,
      onChanged: (bool value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(silentLaunch: value));
      },
    );
  }
}

class AutoRunItem extends ConsumerWidget {
  const AutoRunItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final autoRun = ref.watch(
      appSettingProvider.select((state) => state.autoRun),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.autoRun),
      subtitle: Text(appLocalizations.autoRunDesc),
      value: autoRun,
      onChanged: (bool value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(autoRun: value));
      },
    );
  }
}

class HiddenItem extends ConsumerWidget {
  const HiddenItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final hidden = ref.watch(
      appSettingProvider.select((state) => state.hidden),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.exclude),
      subtitle: Text(appLocalizations.excludeDesc),
      value: hidden,
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(hidden: value));
      },
    );
  }
}

class AnimateTabItem extends ConsumerWidget {
  const AnimateTabItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final isAnimateToPage = ref.watch(
      appSettingProvider.select((state) => state.isAnimateToPage),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.tabAnimation),
      subtitle: Text(appLocalizations.tabAnimationDesc),
      value: isAnimateToPage,
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(isAnimateToPage: value));
      },
    );
  }
}

class OpenLogsItem extends ConsumerWidget {
  const OpenLogsItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final openLogs = ref.watch(
      appSettingProvider.select((state) => state.openLogs),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.logcat),
      subtitle: Text(appLocalizations.logcatDesc),
      value: openLogs,
      onChanged: (bool value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(openLogs: value));
      },
    );
  }
}

class CrashlyticsItem extends ConsumerWidget {
  const CrashlyticsItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final crashlytics = ref.watch(
      appSettingProvider.select((state) => state.crashlytics),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.crashlytics),
      subtitle: Text(appLocalizations.crashlyticsTip),
      value: crashlytics,
      onChanged: (bool value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(crashlytics: value));
      },
    );
  }
}

class AutoCheckUpdateItem extends ConsumerWidget {
  const AutoCheckUpdateItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final autoCheckUpdate = ref.watch(
      appSettingProvider.select((state) => state.autoCheckUpdate),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.autoCheckUpdate),
      subtitle: Text(appLocalizations.autoCheckUpdateDesc),
      value: autoCheckUpdate,
      onChanged: (bool value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(autoCheckUpdate: value));
      },
    );
  }
}

class BatteryOptimizationItem extends ConsumerWidget {
  const BatteryOptimizationItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final isOptimizationDisabled = ref.watch(batteryOptimizationDisableProvider);

    return ListItem(
      leading: Icon(
        isOptimizationDisabled ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
        color: isOptimizationDisabled ? Colors.green : Theme.of(context).colorScheme.error,
      ),
      title: Text(appLocalizations.ignoreBatteryOptimization),
      subtitle: Text(
        isOptimizationDisabled
            ? 'Фоновый режим активен: система не будет усыплять VPN и прокси.'
            : 'Рекомендуется отключить оптимизацию батареи для стабильной работы VPN и TG прокси в фоне. Нажмите для настройки.',
      ),
      trailing: isOptimizationDisabled
          ? const Chip(
              label: Text('Отключено', style: TextStyle(color: Colors.green, fontSize: 12)),
              backgroundColor: Color(0x1A4CAF50),
              side: BorderSide.none,
            )
          : FilledButton.tonal(
              onPressed: () {
                permissions.needWaitingBatteryOptimizationSettings = true;
                app?.openBatteryOptimizationSettings();
              },
              child: const Text('Настроить'),
            ),
      onTap: () {
        permissions.needWaitingBatteryOptimizationSettings = true;
        app?.openBatteryOptimizationSettings();
      },
    );
  }
}

class ApplicationSettingView extends StatelessWidget {
  const ApplicationSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [
      if (system.isAndroid) const BatteryOptimizationItem(),
      if (system.isDesktop) const MinimizeItem(),
      if (system.isDesktop) ...[
        const AutoLaunchItem(),
        const SilentLaunchItem(),
      ],
      const AutoRunItem(),
      const AnimateTabItem(),
      const OpenLogsItem(),
      const CloseConnectionsItem(),
      const UsageItem(),
      if (system.isAndroid) const CrashlyticsItem(),
      const AutoCheckUpdateItem(),
    ];
    return BaseScaffold(
      title: context.appLocalizations.application,
      body: ListView.separated(
        itemBuilder: (_, index) {
          final item = items[index];
          return item;
        },
        separatorBuilder: (_, _) {
          return const Divider(height: 0);
        },
        itemCount: items.length,
      ),
    );
  }
}
