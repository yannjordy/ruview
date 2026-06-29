import 'dart:math';
import 'package:flutter/material.dart';

class _Particle {
  double x, y, size, speed, alpha, phase;
  _Particle(this.x, this.y, this.size, this.speed, this.alpha, this.phase);
}

class SignalParticles extends StatefulWidget {
  final double width;
  final double height;
  final int particleCount;

  const SignalParticles({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.particleCount = 30,
  });

  @override
  State<SignalParticles> createState() => _SignalParticlesState();
}

class _SignalParticlesState extends State<SignalParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final List<_Particle> _particles = [];
  final Random _rng = Random(99);
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initParticles();
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        _rng.nextDouble(),
        _rng.nextDouble(),
        1 + _rng.nextDouble() * 3,
        0.2 + _rng.nextDouble() * 0.5,
        0.05 + _rng.nextDouble() * 0.1,
        _rng.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (ctx, _) {
        _time += 0.016;
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ParticlePainter(_particles, _time, widget.width, widget.height),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time, width, height;

  _ParticlePainter(this.particles, this.time, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final x = (p.x + sin(time * p.speed + p.phase) * 0.15) * width;
      final y = (p.y + cos(time * p.speed * 0.7 + p.phase * 1.3) * 0.1) * height;
      final alpha = (sin(time * 1.5 + p.phase) * 0.5 + 0.5) * p.alpha;

      paint.color = const Color(0xFF00BCD4).withValues(alpha: alpha.clamp(0.0, 0.2));

      final glowPaint = Paint()
        ..color = const Color(0xFF00BCD4).withValues(alpha: (alpha * 0.3).clamp(0.0, 0.1))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), p.size * 3, glowPaint);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
