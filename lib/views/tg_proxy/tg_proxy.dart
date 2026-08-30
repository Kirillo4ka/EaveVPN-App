import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_clash/services/tg_mtproto_bridge.dart';
import 'package:fl_clash/widgets/widgets.dart';

class TgProxyView extends ConsumerStatefulWidget {
  const TgProxyView({super.key});

  @override
  ConsumerState<TgProxyView> createState() => _TgProxyViewState();
}

class _TgProxyViewState extends ConsumerState<TgProxyView> {
  final String _proxyHost = '127.0.0.1';
  final int _proxyPort = 1443;
  final String _secret = 'ddb86fd5a64123a081a8eed2b9bbda13ae';

  @override
  void initState() {
    super.initState();
    TgMtprotoBridge.start(port: _proxyPort);
  }

  String get _mtprotoLink =>
      'tg://proxy?server=$_proxyHost&port=$_proxyPort&secret=$_secret';

  Future<void> _connectToTelegram(BuildContext context) async {
    if (!TgMtprotoBridge.isRunning) {
      await TgMtprotoBridge.start(port: _proxyPort);
    }
    final uri = Uri.parse(_mtprotoLink);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _copyToClipboard(context, _mtprotoLink, 'Ссылка на MTProto скопирована!');
      }
    } catch (_) {
      if (context.mounted) {
        _copyToClipboard(context, _mtprotoLink, 'Ссылка на MTProto скопирована!');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showManualDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const TelegramNavIcon(size: 22),
              const SizedBox(width: 10),
              const Text('Параметры MTProto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildParamTile(ctx, 'Сервер / Host', _proxyHost),
              const SizedBox(height: 8),
              _buildParamTile(ctx, 'Порт / Port', _proxyPort.toString()),
              const SizedBox(height: 8),
              _buildParamTile(ctx, 'Секрет / Secret', _secret),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParamTile(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () => _copyToClipboard(context, value, '$title скопирован!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TG Прокси',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: TgMtprotoBridge.isRunningNotifier,
            builder: (context, isRunning, _) {
              return IconButton(
                tooltip: isRunning ? 'Перезапустить мост' : 'Запустить мост',
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isRunning ? const Color(0xFF22C55E) : null,
                ),
                onPressed: () async {
                  await TgMtprotoBridge.stop();
                  await TgMtprotoBridge.start(port: _proxyPort);
                  if (context.mounted) {
                    _copyToClipboard(context, '127.0.0.1:$_proxyPort', 'TG MTProto мост перезапущен!');
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. Header Banner (Compact & Responsive)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2AABEE).withValues(alpha: 0.16),
                        const Color(0xFF229ED9).withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2AABEE).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(22, 22),
                            painter: TelegramPlanePainter(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Telegram MTProto',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2AABEE).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'WS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF229ED9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Нативный MTProto туннель через защищенный WebSocket',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Status Card (Responsive Layout)
                ValueListenableBuilder<bool>(
                  valueListenable: TgMtprotoBridge.isRunningNotifier,
                  builder: (context, isRunning, _) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRunning
                              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Status dot + Label + Switch
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRunning ? const Color(0xFF22C55E) : Colors.grey,
                                  boxShadow: isRunning
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isRunning ? 'MTProto мост активен' : 'MTProto мост отключен',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isRunning ? const Color(0xFF22C55E) : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$_proxyHost:$_proxyPort',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: isRunning,
                                  onChanged: (val) async {
                                    if (val) {
                                      await TgMtprotoBridge.start(port: _proxyPort);
                                    } else {
                                      await TgMtprotoBridge.stop();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Responsive 3-box Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  context: context,
                                  title: 'Тип',
                                  value: 'MTProto',
                                  icon: Icons.vpn_lock_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoItem(
                                  context: context,
                                  title: 'Транспорт',
                                  value: 'WSS / TLS',
                                  icon: Icons.sync_alt_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoItem(
                                  context: context,
                                  title: 'Медиа',
                                  value: 'Все DC',
                                  icon: Icons.cloud_done_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // 3. Main One-Click Connect Button
                FilledButton.icon(
                  onPressed: () => _connectToTelegram(context),
                  icon: const TelegramNavIcon(size: 20, color: Colors.white),
                  label: const Text(
                    'Подключить MTProto в Telegram (1 клик)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF229ED9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 10),

                // 4. Secondary Action Buttons (Copy & Manual)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(
                          context,
                          _mtprotoLink,
                          'MTProto ссылка скопирована!',
                        ),
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text(
                          'Скопировать ссылку',
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showManualDialog(context),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text(
                          'Параметры вручную',
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Instruction Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Как работает MTProto Proxy?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStep(
                        number: '1',
                        text: 'Нажмите «Подключить MTProto в Telegram». Откроется ваш клиент Telegram.',
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _buildStep(
                        number: '2',
                        text: 'В диалоге Telegram нажмите «Включить прокси-сервер». В шапке появится щит 🛡️.',
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _buildStep(
                        number: '3',
                        text: 'MTProto туннелируется через защищенный WebSocket, обходя любые ограничения.',
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF229ED9)),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String text,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
