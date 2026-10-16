import 'dart:math';
import 'package:flutter/material.dart';

class BarData {
  final String label;
  final double value;
  final Color color;

  BarData({required this.label, required this.value, required this.color});
}

class BarChartPainter extends CustomPainter {
  final List<BarData> bars;
  final double animationProgress;

  BarChartPainter({required this.bars, this.animationProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final maxValue = bars.map((b) => b.value).reduce(max);
    if (maxValue <= 0) return;

    final padding = 24.0;
    final availableWidth = size.width - (padding * 2);
    final barWidth = (availableWidth / bars.length) * 0.55;
    final spacing = (availableWidth / bars.length) * 0.45;
    final chartHeight = size.height - 30;

    for (int i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final x = padding + i * (barWidth + spacing) + spacing / 2;
      final targetBarHeight = (bar.value / maxValue) * chartHeight;
      final currentBarHeight = targetBarHeight * animationProgress;
      final y = chartHeight - currentBarHeight;

      // Dibujar barra con RRect
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, currentBarHeight),
        const Radius.circular(8),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [bar.color.withOpacity(0.6), bar.color],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, currentBarHeight));

      canvas.drawRRect(rect, paint);

      // Label en eje X
      final textPainter = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + (barWidth - textPainter.width) / 2, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.bars != bars;
  }
}
