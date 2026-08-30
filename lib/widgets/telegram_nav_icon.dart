import 'package:fl_clash/services/tg_mtproto_bridge.dart';
import 'package:flutter/material.dart';

/// Authentic Telegram Paper Plane Icon Painter
class TelegramPlanePainter extends CustomPainter {
  final Color color;
  final bool hasGlow;

  TelegramPlanePainter({
    required this.color,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (hasGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      _drawPlane(canvas, w, h, glowPaint);
    }

    _drawPlane(canvas, w, h, paint);
  }

  void _drawPlane(Canvas canvas, double w, double h, Paint paint) {
    final path = Path();
    
    // Perfectly centered Telegram airplane silhouette
    path.moveTo(w * 0.88, h * 0.20);
    path.lineTo(w * 0.16, h * 0.50);
    path.cubicTo(w * 0.11, h * 0.52, w * 0.11, h * 0.58, w * 0.19, h * 0.61);
    path.lineTo(w * 0.36, h * 0.67);
    path.lineTo(w * 0.74, h * 0.34);
    path.cubicTo(w * 0.77, h * 0.31, w * 0.80, h * 0.34, w * 0.77, h * 0.38);
    path.lineTo(w * 0.44, h * 0.73);
    path.lineTo(w * 0.41, h * 0.85);
    path.cubicTo(w * 0.40, h * 0.90, w * 0.45, h * 0.92, w * 0.49, h * 0.88);
    path.lineTo(w * 0.60, h * 0.78);
    path.lineTo(w * 0.78, h * 0.89);
    path.cubicTo(w * 0.84, h * 0.93, w * 0.89, h * 0.90, w * 0.91, h * 0.83);
    path.lineTo(w * 0.94, h * 0.27);
    path.cubicTo(w * 0.96, h * 0.20, w * 0.92, h * 0.17, w * 0.88, h * 0.20);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TelegramPlanePainter oldDelegate) =>
      color != oldDelegate.color || hasGlow != oldDelegate.hasGlow;
}

/// Navigation Icon with authentic Telegram silhouette & dynamic status indicator
class TelegramNavIcon extends Icon {
  const TelegramNavIcon({
    super.key,
    super.size = 24.0,
    super.color,
  }) : super(Icons.send_rounded);

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 24.0;
    return ValueListenableBuilder<bool>(
      valueListenable: TgMtprotoBridge.isRunningNotifier,
      builder: (context, isRunning, _) {
        final activeColor = color ?? const Color(0xFF29B6F6);
        final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
        final planeColor = isRunning ? activeColor : (color ?? inactiveColor);

        return SizedBox(
          width: effectiveSize,
          height: effectiveSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(effectiveSize, effectiveSize),
                painter: TelegramPlanePainter(
                  color: planeColor,
                  hasGlow: isRunning,
                ),
              ),
              // Status indicator badge in bottom-right corner with outline
              Positioned(
                right: -3,
                bottom: -3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isRunning ? 8.0 : 0.0,
                  height: isRunning ? 8.0 : 0.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                    boxShadow: isRunning
                        ? [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
