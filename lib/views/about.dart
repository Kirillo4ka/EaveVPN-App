import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:fl_clash/widgets/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class Contributor {
  final String avatar;
  final String name;
  final String link;
  final String? badge;
  final String? subtitle;

  const Contributor({
    required this.avatar,
    required this.name,
    required this.link,
    this.badge,
    this.subtitle,
  });
}

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  Future<void> _checkUpdate(BuildContext context) async {
    globalState.openUrl('https://github.com/Kirillo4ka/EaveVPN/releases/latest');
  }

  List<Widget> _buildMoreSection(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return generateSection(
      separated: false,
      title: appLocalizations.more,
      items: [
        ListItem(
          title: Text(appLocalizations.checkUpdate),
          subtitle: const Text('Перейти к свежему релизу на GitHub'),
          onTap: () {
            _checkUpdate(context);
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: const Text('Telegram канал'),
          subtitle: const Text('@EaveVPN'),
          onTap: () {
            globalState.openUrl('https://t.me/EaveVPN');
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: const Text('Официальный сайт'),
          subtitle: const Text('https://eavevpn.fastedge.workers.dev'),
          onTap: () {
            globalState.openUrl('https://eavevpn.fastedge.workers.dev');
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: const Text('GitHub Профиль'),
          subtitle: const Text('https://github.com/Kirillo4ka'),
          onTap: () {
            globalState.openUrl('https://github.com/Kirillo4ka');
          },
          trailing: const Icon(Icons.launch),
        ),
      ],
    );
  }

  List<Widget> _buildContributorsSection(AppLocalizations appLocalizations) {
    const contributors = [
      Contributor(
        avatar: 'assets/images/avatar/kirillo4ka.jpg',
        name: 'Kirillo4ka',
        link: 'https://github.com/Kirillo4ka',
        subtitle: 'Разработчик',
      ),
    ];
    return generateSection(
      separated: false,
      title: 'Разработчик',
      items: [
        ListItem(
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 24,
              children: [
                for (final contributor in contributors)
                  Avatar(contributor: contributor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final items = [
      ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (_, ref, _) {
                return _DeveloperModeDetector(
                  child: Wrap(
                    spacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'v1.0.0',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                  onEnterDeveloperMode: () {
                    ref
                        .read(appSettingProvider.notifier)
                        .update((state) => state.copyWith(developerMode: true));
                    context.showNotifier(
                      appLocalizations.developerModeEnableTip,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'EaveVPN — современный и быстрый клиент для безопасного доступа в интернет.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Особенности EaveVPN:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Автоматическая загрузка зашифрованных серверов\n'
              '• Быстрый TCP Handshake замер задержки серверов\n'
              '• Авто-маскировка uTLS Chrome для обхода блокировок\n'
              '• Поддержка системного TUN-режима',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ..._buildContributorsSection(appLocalizations),
      ..._buildMoreSection(context),
    ];
    return BaseScaffold(
      title: appLocalizations.about,
      body: Padding(
        padding: kMaterialListPadding.copyWith(top: 16, bottom: 16),
        child: generateListView(items),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final Contributor contributor;

  const Avatar({super.key, required this.contributor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        globalState.openUrl(contributor.link);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircleAvatar(
              foregroundImage: AssetImage(contributor.avatar),
            ),
          ),
          const SizedBox(height: 4),
          Text(contributor.name, style: context.textTheme.bodySmall),
          if (contributor.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              contributor.subtitle!,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeveloperModeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onEnterDeveloperMode;

  const _DeveloperModeDetector({
    required this.child,
    required this.onEnterDeveloperMode,
  });

  @override
  State<_DeveloperModeDetector> createState() => _DeveloperModeDetectorState();
}

class _DeveloperModeDetectorState extends State<_DeveloperModeDetector> {
  int _count = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap() {
    _timer?.cancel();
    _count++;
    if (_count == 5) {
      widget.onEnterDeveloperMode();
      _count = 0;
      return;
    }
    _timer = Timer(const Duration(seconds: 1), () {
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: widget.child,
    );
  }
}
