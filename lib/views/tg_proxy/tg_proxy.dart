import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_clash/services/tg_mtproto_bridge.dart';

class TgProxyView extends ConsumerStatefulWidget {
  const TgProxyView({super.key});

  @override
  ConsumerState<TgProxyView> createState() => _TgProxyViewState();
}

class _TgProxyViewState extends ConsumerState<TgProxyView> {
  final String _proxyHost = '127.0.0.1';
  final int _proxyPort = 9090;
  final String _secret =
      'ee000000000000000000000000000000007777772e676f6f676c652e636f6d';
  late TextEditingController _workerController;

  @override
  void initState() {
    super.initState();
    _workerController = TextEditingController(text: TgMtprotoBridge.workerUrl);
    // Auto-start MTProto bridge
    TgMtprotoBridge.start(port: _proxyPort);
  }

  @override
  void dispose() {
    _workerController.dispose();
    super.dispose();
  }

  String get _mtprotoLink =>
      'tg://proxy?server=\$_proxyHost&port=\$_proxyPort&secret=\$_secret';

  Future<void> _connectToTelegram(BuildContext context) async {
    if (!TgMtprotoBridge.isRunning) {
      await TgMtprotoBridge.start(port: _proxyPort);
    }

    final tgUri = Uri.parse(_mtprotoLink);
    final webFallback = Uri.parse(
      'https://t.me/proxy?server=\$_proxyHost&port=\$_proxyPort&secret=\$_secret',
    );

    try {
      if (await canLaunchUrl(tgUri)) {
        await launchUrl(tgUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webFallback)) {
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(tgUri, mode: LaunchMode.externalNonBrowserApplication);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Открываю Telegram для подключения MTProto Proxy...'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка запуска Telegram: \$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _copyTgLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _mtprotoLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ссылка скопирована в буфер обмена!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyParams(BuildContext context) {
    Clipboard.setData(
      ClipboardData(
        text:
            'Тип: MTProto\nСервер: \$_proxyHost\nПорт: \$_proxyPort\nСекрет: \$_secret',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Параметры MTProto скопированы (\$_proxyHost:\$_proxyPort)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // 1. Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2AABEE).withValues(alpha: 0.18),
                      const Color(0xFF229ED9).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2AABEE).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Telegram MTProto WS-Прокси',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2AABEE)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'MTProto',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF229ED9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Нативный защищенный MTProto туннель для обхода любых блокировок в Telegram',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Status Card
              ValueListenableBuilder<bool>(
                valueListenable: TgMtprotoBridge.isRunningNotifier,
                builder: (context, isRunning, _) {
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isRunning
                                          ? Colors.greenAccent.shade400
                                          : Colors.amberAccent.shade400,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isRunning
                                                  ? Colors.green
                                                  : Colors.amber)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isRunning
                                        ? 'MTProto мост активен'
                                        : 'Мост остановлен',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '\$_proxyHost:\$_proxyPort',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      isRunning
                                          ? Icons.stop_circle_outlined
                                          : Icons.play_circle_fill_outlined,
                                      color: isRunning
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      if (isRunning) {
                                        TgMtprotoBridge.stop();
                                      } else {
                                        TgMtprotoBridge.start(port: _proxyPort);
                                      }
                                    },
                                    tooltip: isRunning
                                        ? 'Остановить мост'
                                        : 'Запустить мост',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              _buildDetailChip(
                                context: context,
                                label: 'Тип прокси',
                                value: 'MTProto Fake-TLS',
                              ),
                              const SizedBox(width: 12),
                              _buildDetailChip(
                                context: context,
                                label: 'Транспорт',
                                value: 'TLS / WebSocket',
                              ),
                              const SizedBox(width: 12),
                              _buildDetailChip(
                                context: context,
                                label: 'Звонки / Медиа',
                                value: 'Поддерживаются',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 3. Worker URL Configuration Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_queue_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _workerController,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          labelText: 'Cloudflare Worker URL / Шлюз',
                          hintText: 'https://eave-tg.fastedge.workers.dev',
                        ),
                        onChanged: (val) {
                          TgMtprotoBridge.setWorkerUrl(val);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, size: 20),
                      onPressed: () {
                        TgMtprotoBridge.setWorkerUrl(_workerController.text);
                        TgMtprotoBridge.start(port: _proxyPort);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Шлюз обновлен и перезапущен!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Применить адрес',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Main Action Button: Connect to Telegram
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _connectToTelegram(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF229ED9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.telegram, size: 24),
                  label: const Text(
                    'Подключить MTProto в Telegram (1 клик)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 5. Secondary Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyTgLink(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Скопировать MTProto ссылку'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyParams(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.copy_all, size: 18),
                      label: const Text('Параметры вручную'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 6. Instruction Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Как работает нативный MTProto Proxy?',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      context: context,
                      number: '1',
                      text:
                          'Нажмите «Подключить MTProto в Telegram». Откроется ваш клиент Telegram.',
                    ),
                    const SizedBox(height: 8),
                    _buildStepRow(
                      context: context,
                      number: '2',
                      text:
                          'В диалоговом окне Telegram нажмите «Включить прокси-сервер». В шапке Telegram появится щит 🛡️.',
                    ),
                    const SizedBox(height: 8),
                    _buildStepRow(
                      context: context,
                      number: '3',
                      text:
                          'MTProto туннелируется через защищенный WebSocket, обходя блокировки и ограничения звонков.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required BuildContext context,
    required String number,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer,
          ),
          child: Text(
            number,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
