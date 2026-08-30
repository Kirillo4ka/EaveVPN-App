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
        ..color = color.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      _drawPlane(canvas, w, h, glowPaint);
    }

    _drawPlane(canvas, w, h, paint);
  }

  void _drawPlane(Canvas canvas, double w, double h, Paint paint) {
    // Official Telegram paper airplane vector path normalized to width & height
    final path = Path();
    
    // Top right point (nose of the airplane)
    path.moveTo(w * 0.88, h * 0.16);
    // Main wing edge down to bottom left
    path.lineTo(w * 0.14, h * 0.49);
    // Back curve of left wing
    path.cubicTo(w * 0.09, h * 0.51, w * 0.09, h * 0.57, w * 0.17, h * 0.60);
    // Bottom fold to inner wing
    path.lineTo(w * 0.35, h * 0.67);
    // Inner fold line to nose
    path.lineTo(w * 0.76, h * 0.30);
    // Nose curve
    path.cubicTo(w * 0.79, h * 0.27, w * 0.82, h * 0.30, w * 0.79, h * 0.34);
    // Inner wing to keel bottom
    path.lineTo(w * 0.43, h * 0.73);
    // Keel fin
    path.lineTo(w * 0.40, h * 0.86);
    path.cubicTo(w * 0.39, h * 0.91, w * 0.44, h * 0.93, w * 0.48, h * 0.89);
    path.lineTo(w * 0.60, h * 0.78);
    // Right wing outer edge
    path.lineTo(w * 0.80, h * 0.91);
    path.cubicTo(w * 0.86, h * 0.95, w * 0.91, h * 0.92, w * 0.93, h * 0.84);
    // Leading edge back to nose
    path.lineTo(w * 0.96, h * 0.23);
    path.cubicTo(w * 0.98, h * 0.16, w * 0.94, h * 0.13, w * 0.88, h * 0.16);
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
          width: effectiveSize + 4,
          height: effectiveSize + 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: CustomPaint(
                  size: Size(effectiveSize, effectiveSize),
                  painter: TelegramPlanePainter(
                    color: planeColor,
                    hasGlow: isRunning,
                  ),
                ),
              ),
              // State indicator badge (Green pulsing/glowing dot when active)
              Positioned(
                right: 0,
                top: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isRunning ? 8.0 : 6.0,
                  height: isRunning ? 8.0 : 6.0,
                  decoration: BoxDecoration(
                    color: isRunning
                        ? const Color(0xFF22C55E)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isRunning
                        ? [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withOpacity(0.7),
                              blurRadius: 5,
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
