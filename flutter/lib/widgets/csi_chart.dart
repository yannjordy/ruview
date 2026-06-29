import 'dart:math';
import 'package:flutter/material.dart';

class CsiChart extends StatelessWidget {
  const CsiChart({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CsiChartPainter(),
      size: Size.infinite,
    );
  }
}

class _CsiChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final rng = Random(42);
    final amplitudes = List.generate(80, (_) => rng.nextDouble());

    for (int sub = 0; sub < 3; sub++) {
      final paint = Paint()
        ..color = [
          const Color(0xFF00BCD4),
          const Color(0xFF42A5F5),
          const Color(0xFF26C6DA),
        ][sub].withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < amplitudes.length; i++) {
        final x = (i / amplitudes.length) * size.width;
        final y = size.height / 2 +
            (amplitudes[i] - 0.5) * size.height * 0.8 *
                (1 + sub * 0.3) +
            sub * 15;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    final labelPaint = TextStyle(
      color: Colors.white24,
      fontSize: 10,
      fontFamily: 'monospace',
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(text: 'CSI amplitude (simulé)', style: labelPaint);
    textPainter.layout();
    textPainter.paint(canvas, Offset(8, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
