import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PingType {
  proxyGet('via Proxy GET'),
  proxyHead('via Proxy HEAD'),
  tcp('TCP'),
  icmp('ICMP');

  final String label;
  const PingType(this.label);

  static PingType fromString(String? name) {
    if (name == null) return PingType.tcp;
    return PingType.values.firstWhere(
      (e) => e.name == name || e.label == name,
      orElse: () => PingType.tcp,
    );
  }
}

class PingTypeNotifier extends Notifier<PingType> {
  @override
  PingType build() {
    _loadFromPrefs();
    return PingType.tcp;
  }

  Future<void> _loadFromPrefs() async {
    final saved = await preferences.getString('pingType');
    if (saved != null) {
      state = PingType.fromString(saved);
    }
  }

  Future<void> setType(PingType type) async {
    state = type;
    await preferences.setString('pingType', type.name);
  }
}

final pingTypeProvider =
    NotifierProvider<PingTypeNotifier, PingType>(PingTypeNotifier.new);

class PingSettingView extends ConsumerStatefulWidget {
  const PingSettingView({super.key});

  @override
  ConsumerState<PingSettingView> createState() => _PingSettingViewState();
}

class _PingSettingViewState extends ConsumerState<PingSettingView> {
  late PingType _selectedType;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _selectedType = ref.read(pingTypeProvider);
    final currentUrl =
        ref.read(appSettingProvider.select((state) => state.testUrl));
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _applySettings() async {
    // 1. Save ping type
    await ref.read(pingTypeProvider.notifier).setType(_selectedType);

    // 2. Save test URL
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      ref
          .read(appSettingProvider.notifier)
          .update((state) => state.copyWith(testUrl: newUrl));
    }

    if (!mounted) return;

    // 3. Show feedback SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Настройки применены: тип «${_selectedType.label}»',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildPingTypeSection(ThemeData theme) {
    final cardColor = theme.cardColor.withOpacity(0.5);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < PingType.values.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Colors.white10),
            InkWell(
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(8) : Radius.zero,
                bottom: i == PingType.values.length - 1
                    ? const Radius.circular(8)
                    : Radius.zero,
              ),
              onTap: () {
                setState(() {
                  _selectedType = PingType.values[i];
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Radio<PingType>(
                      value: PingType.values[i],
                      groupValue: _selectedType,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      PingType.values[i].label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestUrlSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _urlController,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildApplyButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _applySettings,
          icon: const Icon(Icons.check, size: 20),
          label: const Text(
            'Применить',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseScaffold(
      title: '${context.appLocalizations.tools} > Пинг',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Тип пинга'),
          _buildPingTypeSection(theme),
          _buildSectionHeader('Тестовый URL (via Proxy)'),
          _buildTestUrlSection(theme),
          _buildApplyButton(theme),
        ],
      ),
    );
  }
}
