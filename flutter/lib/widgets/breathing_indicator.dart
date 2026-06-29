import 'dart:math';
import 'package:flutter/material.dart';

class BreathingIndicator extends StatefulWidget {
  final double width;
  final double height;
  final double? breathingRate;
  final double? confidence;

  const BreathingIndicator({
    super.key,
    this.width = 80,
    this.height = 80,
    this.breathingRate,
    this.confidence,
  });

  @override
  State<BreathingIndicator> createState() => _BreathingIndicatorState();
}

class _BreathingIndicatorState extends State<BreathingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double bpm = widget.breathingRate ?? 16;
    double speed = bpm / 60.0;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (ctx, _) {
        _phase += 0.016 * speed;
        if (_phase > 2 * pi) _phase -= 2 * pi;

        final breathValue = sin(_phase) * 0.5 + 0.5;
        final expand = 1.0 + breathValue * 0.15;

        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _BreathingPainter(breathValue, expand, bpm),
        );
      },
    );
  }
}

class _BreathingPainter extends CustomPainter {
  final double breathValue, expand, bpm;

  _BreathingPainter(this.breathValue, this.expand, this.bpm);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final baseR = min(size.width, size.height) * 0.3;
    final r = baseR * expand;

    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), baseR * 1.5, bgPaint);

    final glowPaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: breathValue * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy), r * 2, glowPaint);

    final outerPaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.15 + breathValue * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), r * 1.3, outerPaint);

    final midPaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.25 + breathValue * 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.8, midPaint);

    final corePaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF2196F3),
        const Color(0xFF00BCD4),
        breathValue,
      )!.withValues(alpha: 0.5 + breathValue * 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.4, corePaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: breathValue * 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - r * 0.15, cy - r * 0.15), r * 0.12, highlightPaint);

    if (bpm > 0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${bpm.toStringAsFixed(0)}',
          style: TextStyle(
            color: const Color(0xFF42A5F5).withValues(alpha: 0.6 + breathValue * 0.2),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, size.height - 22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BreathingPainter old) => old.breathValue != breathValue;
}
