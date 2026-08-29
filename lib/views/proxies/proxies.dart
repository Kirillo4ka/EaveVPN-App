import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/models/state.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/proxies/list.dart';
import 'package:fl_clash/views/proxies/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'setting.dart';
import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key});

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView> {
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();
  bool _hasProviders = false;
  bool _isTab = false;

  List<Widget> _buildActions(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return [
      ValueListenableBuilder<bool>(
        valueListenable: EaveVpnSync.isSyncingNotifier,
        builder: (context, isSyncing, _) {
          return IconButton(
            tooltip: 'Обновить серверы',
            onPressed: isSyncing
                ? null
                : () async {
                    final res = await EaveVpnSync.syncConfigs(force: true);
                    if (context.mounted && res) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Конфигурации успешно обновлены!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            icon: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          );
        },
      ),
      if (_isTab)
        IconButton(
          onPressed: () {
            _proxiesTabKey.currentState?.scrollToGroupSelected();
          },
          icon: const Icon(Icons.adjust, weight: 1),
        ),
      CommonPopupBox(
        targetBuilder: (open) {
          return IconButton(
            onPressed: () {
              final isMobile = ref.read(isMobileViewProvider);
              open(offset: Offset(0, isMobile ? 0 : 20));
            },
            icon: const Icon(Icons.more_vert),
          );
        },
        popup: CommonPopupMenu(
          items: [
            PopupMenuItemData(
              icon: Icons.tune,
              label: appLocalizations.settings,
              onPressed: () {
                showSheet(
                  context: context,
                  props: const SheetProps(isScrollControlled: true),
                  builder: (_) {
                    return AdaptiveSheetScaffold(
                      body: const ProxiesSetting(),
                      title: appLocalizations.settings,
                    );
                  },
                );
              },
            ),
            if (_hasProviders)
              PopupMenuItemData(
                icon: Icons.poll_outlined,
                label: appLocalizations.providers,
                onPressed: () {
                  showExtend(
                    context,
                    builder: (_) {
                      return const ProvidersView();
                    },
                  );
                },
              ),
          ],
        ),
      ),
    ];
  }

  Widget? _buildFAB() {
    return _isTab
        ? DelayTestButton(
            onClick: () async {
              await _proxiesTabKey.currentState?.delayTestCurrentGroup();
            },
          )
        : null;
  }

  void _onSearch(String value) {
    ref.read(queryProvider(QueryTag.proxies).notifier).value = value;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profs = ref.read(profilesProvider);
      final grps = ref.read(groupsProvider);
      if (profs.isEmpty || grps.isEmpty) {
        EaveVpnSync.syncConfigs();
      }
    });
    ref.listenManual(providersProvider.select((state) => state.isNotEmpty), (
      prev,
      next,
    ) {
      if (prev != next) {
        setState(() {
          _hasProviders = next;
        });
      }
    }, fireImmediately: true);
    ref.listenManual(
      proxiesStyleSettingProvider.select(
        (state) => state.type == ProxiesType.tab,
      ),
      (prev, next) {
        if (prev != next) {
          setState(() {
            _isTab = next;
          });
        }
      },
      fireImmediately: true,
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    final theme = Theme.of(context);

    // PC / Desktop Version: Single unified list with clean last updated status
    if (system.isDesktop) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Все серверы (Единый список)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<DateTime?>(
              valueListenable: EaveVpnSync.lastSyncNotifier,
              builder: (context, _, _) {
                return Text(
                  '⚡ ${EaveVpnSync.getLastSyncText()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Android / Mobile Version: Clean 2-way switcher (VPN vs Обход блокировок) without subtitles
    final profiles = ref.watch(profilesProvider);
    final currentProfileId = ref.watch(currentProfileIdProvider);

    Profile? vpnProfile;
    Profile? unblockProfile;
    for (final p in profiles) {
      if (p.label == 'VPN') vpnProfile = p;
      if (p.label == 'Обход блокировок') unblockProfile = p;
    }

    if (vpnProfile == null && unblockProfile == null) {
      return const SizedBox.shrink();
    }

    final selectedId =
        currentProfileId ?? vpnProfile?.id ?? unblockProfile?.id ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (vpnProfile != null)
                Expanded(
                  child: _buildModeTab(
                    context: context,
                    label: 'VPN',
                    icon: Icons.vpn_lock,
                    isSelected: selectedId == vpnProfile.id,
                    onTap: () {
                      if (selectedId != vpnProfile!.id) {
                        ref.read(currentProfileIdProvider.notifier).value =
                            vpnProfile.id;
                        ref
                            .read(setupActionProvider.notifier)
                            .applyProfileDebounce();
                      }
                    },
                  ),
                ),
              if (vpnProfile != null && unblockProfile != null)
                const SizedBox(width: 6),
              if (unblockProfile != null)
                Expanded(
                  child: _buildModeTab(
                    context: context,
                    label: 'Обход блокировок',
                    icon: Icons.shield_outlined,
                    isSelected: selectedId == unblockProfile.id,
                    onTap: () {
                      if (selectedId != unblockProfile!.id) {
                        ref.read(currentProfileIdProvider.notifier).value =
                            unblockProfile.id;
                        ref
                            .read(setupActionProvider.notifier)
                            .applyProfileDebounce();
                      }
                    },
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: ValueListenableBuilder<DateTime?>(
              valueListenable: EaveVpnSync.lastSyncNotifier,
              builder: (context, _, _) {
                return Text(
                  '⚡ ${EaveVpnSync.getLastSyncText()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: theme.colorScheme.outline,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proxiesType = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.type),
    );
    final isLoading = ref.watch(loadingProvider(LoadingTag.proxies));
    final profiles = ref.watch(profilesProvider);

    return CommonScaffold(
      isLoading: isLoading,
      resizeToAvoidBottomInset: false,
      floatingActionButton: _buildFAB(),
      actions: _buildActions(context),
      title: context.appLocalizations.proxies,
      searchState: AppBarSearchState(onSearch: _onSearch),
      body: (profiles.isEmpty || ref.watch(groupsProvider).isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Пожалуйста, подождите, загружаем серверы...',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Автоматическая синхронизация и проверка доступности серверов EaveVPN',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                _buildModeSelector(context),
                Expanded(
                  child: switch (proxiesType) {
                    ProxiesType.tab => ProxiesTabView(key: _proxiesTabKey),
                    ProxiesType.list => const ProxiesListView(),
                  },
                ),
              ],
            ),
    );
  }
}
