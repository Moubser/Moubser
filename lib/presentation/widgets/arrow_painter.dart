import 'package:flutter/material.dart';

/// Draws an AR-style directional arrow on a transparent canvas.
/// [rotation] is in radians – 0 means pointing up (straight ahead).
class ArrowPainter extends CustomPainter {
  final double rotation;
  final Color color;

  ArrowPainter({required this.rotation, this.color = const Color(0xFF5EBAA0)});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arrowLength = size.width * 0.35;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    // Arrow body
    final arrowPath = Path()
      ..moveTo(0, -arrowLength)                       // tip
      ..lineTo(arrowLength * 0.35, arrowLength * 0.2)  // right wing
      ..lineTo(0, arrowLength * 0.05)                  // center notch
      ..lineTo(-arrowLength * 0.35, arrowLength * 0.2) // left wing
      ..close();

    // Glow layer
    canvas.drawPath(arrowPath, paint);

    // Solid layer on top
    final solidPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, solidPaint);

    // White outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(arrowPath, outlinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
