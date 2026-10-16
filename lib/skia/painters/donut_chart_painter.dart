import 'dart:math';
import 'package:flutter/material.dart';

class CategoryArcData {
  final String category;
  final double amount;
  final Color color;

  CategoryArcData({required this.category, required this.amount, required this.color});
}

class DonutChartPainter extends CustomPainter {
  final List<CategoryArcData> data;
  final double animationProgress; // 0.0 a 1.0
  final String currencySymbol;

  DonutChartPainter({
    required this.data,
    this.animationProgress = 1.0,
    this.currencySymbol = '\$',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.fold<double>(0.0, (sum, item) => sum + item.amount);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    final strokeWidth = radius * 0.35;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2;

    for (final item in data) {
      final sweepAngle = (item.amount / total) * (2 * pi) * animationProgress;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = item.color;

      canvas.drawArc(rect, startAngle + 0.03, sweepAngle - 0.06, false, paint);
      startAngle += sweepAngle;
    }

    // Dibujar texto central
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Total\n$currencySymbol${total.toStringAsFixed(0)}',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.25,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.data != data;
  }
}
