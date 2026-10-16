import 'dart:math';
import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color lineColors;
  final double animationProgress;

  LineChartPainter({
    required this.points,
    this.lineColors = const Color(0xFF2A5CAA),
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minY = points.reduce(min);
    final maxY = points.reduce(max);
    final rangeY = (maxY - minY) == 0 ? 1.0 : (maxY - minY);

    final double stepX = size.width / (points.length - 1);

    final path = Path();
    final fillPath = Path();

    final List<Offset> offsets = [];

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalizedY = (points[i] - minY) / rangeY;
      final y = size.height - (normalizedY * (size.height - 20) + 10);
      offsets.add(Offset(x, y));
    }

    // Trazo suavizado Bézier
    path.moveTo(offsets[0].dx, offsets[0].dy);
    fillPath.moveTo(offsets[0].dx, size.height);
    fillPath.lineTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );

      fillPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Dibujar área de relleno con gradiente
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColors.withOpacity(0.35), lineColors.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Dibujar línea principal
    final linePaint = Paint()
      ..color = lineColors
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Dibujar puntos Highlight
    final dotPaint = Paint()..color = lineColors;
    final dotInnerPaint = Paint()..color = Colors.white;

    for (final offset in offsets) {
      canvas.drawCircle(offset, 5, dotPaint);
      canvas.drawCircle(offset, 2.5, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.points != points;
  }
}
