import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated semicircular gauge showing diabetes risk probability.
class RiskGauge extends StatelessWidget {
  const RiskGauge({
    super.key,
    required this.probability,
    required this.tierLabel,
    required this.tierColor,
  });

  final double probability;
  final String tierLabel;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 220,
      height: 140,
      child: CustomPaint(
        painter: _GaugePainter(
          probability: probability,
          tierColor: tierColor,
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${(probability * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: tierColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tierLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: tierColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.probability,
    required this.tierColor,
    required this.backgroundColor,
  });

  final double probability;
  final Color tierColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 16;
    const strokeWidth = 14.0;
    const startAngle = math.pi; // left
    const sweepTotal = math.pi; // 180°

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Gradient progress arc
    final sweepAngle = sweepTotal * probability.clamp(0.0, 1.0);
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepTotal,
      colors: [
        Colors.green.shade400,
        Colors.amber.shade500,
        Colors.red.shade500,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Indicator dot
    final indicatorAngle = startAngle + sweepAngle;
    final dx = center.dx + radius * math.cos(indicatorAngle);
    final dy = center.dy + radius * math.sin(indicatorAngle);
    canvas.drawCircle(
      Offset(dx, dy),
      8,
      Paint()..color = tierColor,
    );
    canvas.drawCircle(
      Offset(dx, dy),
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.probability != probability || old.tierColor != tierColor;
}
