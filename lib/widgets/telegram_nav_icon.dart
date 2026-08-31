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
    
    // Mathematically centered Telegram airplane silhouette (center exactly at 0.50, 0.50)
    path.moveTo(w * 0.83, h * 0.155);
    path.lineTo(w * 0.11, h * 0.455);
    path.cubicTo(w * 0.06, h * 0.475, w * 0.06, h * 0.535, w * 0.14, h * 0.565);
    path.lineTo(w * 0.31, h * 0.625);
    path.lineTo(w * 0.69, h * 0.295);
    path.cubicTo(w * 0.72, h * 0.265, w * 0.75, h * 0.295, w * 0.72, h * 0.335);
    path.lineTo(w * 0.39, h * 0.685);
    path.lineTo(w * 0.36, h * 0.805);
    path.cubicTo(w * 0.35, h * 0.855, w * 0.40, h * 0.875, w * 0.44, h * 0.835);
    path.lineTo(w * 0.55, h * 0.735);
    path.lineTo(w * 0.73, h * 0.845);
    path.cubicTo(w * 0.79, h * 0.885, w * 0.84, h * 0.855, w * 0.86, h * 0.785);
    path.lineTo(w * 0.89, h * 0.225);
    path.cubicTo(w * 0.91, h * 0.155, w * 0.87, h * 0.125, w * 0.83, h * 0.155);
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
    super.size,
    super.color,
  }) : super(Icons.send_rounded);

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final effectiveSize = size ?? iconTheme.size ?? 24.0;
    final effectiveColor = color ?? iconTheme.color;
    return ValueListenableBuilder<bool>(
      valueListenable: TgMtprotoBridge.isRunningNotifier,
      builder: (context, isRunning, _) {
        final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
        final planeColor = isRunning ? const Color(0xFF29B6F6) : (effectiveColor ?? inactiveColor);

        return SizedBox(
          width: effectiveSize,
          height: effectiveSize,
          child: Center(
            child: CustomPaint(
              size: Size(effectiveSize, effectiveSize),
              painter: TelegramPlanePainter(
                color: planeColor,
                hasGlow: isRunning,
              ),
            ),
          ),
        );
      },
    );
  }
}
