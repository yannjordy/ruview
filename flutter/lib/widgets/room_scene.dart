import 'dart:math';
import 'package:flutter/material.dart';
import 'pose_3d_math.dart';

class _Occupant {
  Vec3 position;
  double phase;
  double speed;
  Color color;

  _Occupant(this.position, {this.phase = 0, this.speed = 0.5, Color? color})
      : color = color ?? const Color(0xFF00BCD4);
}

class RoomScene3D extends StatefulWidget {
  final double width;
  final double height;
  final int occupantCount;

  const RoomScene3D({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.occupantCount = 0,
  });

  @override
  State<RoomScene3D> createState() => _RoomScene3DState();
}

class _RoomScene3DState extends State<RoomScene3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final Projection _proj = Projection(fov: 55, aspect: 1);
  final Random _rng = Random(84);
  final List<_Occupant> _occupants = [];
  double _rotY = 0.4, _rotX = 0.3;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _initOccupants();
  }

  void _initOccupants() {
    _occupants.clear();
    for (int i = 0; i < widget.occupantCount; i++) {
      _occupants.add(_Occupant(
        Vec3(
          (_rng.nextDouble() - 0.5) * 1.2,
          0,
          (_rng.nextDouble() - 0.5) * 1.2,
        ),
        phase: _rng.nextDouble() * 2 * pi,
        speed: 0.3 + _rng.nextDouble() * 0.4,
        color: Color.fromARGB(
          255,
          0,
          180 + _rng.nextInt(76).toInt(),
          200 + _rng.nextInt(56).toInt(),
        ),
      ));
    }
  }

  @override
  void didUpdateWidget(RoomScene3D old) {
    super.didUpdateWidget(old);
    if (widget.occupantCount != old.occupantCount) {
      _initOccupants();
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
        final dt = _animCtrl.lastElapsedDuration?.inMicroseconds.toDouble() ?? 16666;
        _time += dt * 0.000001;
        _rotY += dt * 0.0000002;

        for (final occ in _occupants) {
          occ.phase += dt * 0.000003 * occ.speed;
          occ.position = Vec3(
            occ.position.x + sin(_time * occ.speed + occ.phase) * 0.0005,
            0.3 + sin(_time * occ.speed * 1.3 + occ.phase) * 0.15,
            occ.position.z + cos(_time * occ.speed * 0.7 + occ.phase * 1.2) * 0.0005,
          );
        }

        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _RoomScenePainter(_proj, _rotY, _rotX, _occupants, _time),
        );
      },
    );
  }
}

class _RoomScenePainter extends CustomPainter {
  final Projection proj;
  final double rotY, rotX, time;
  final List<_Occupant> occupants;

  _RoomScenePainter(this.proj, this.rotY, this.rotX, this.occupants, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    proj.aspect = size.width / size.height;
    final scale = min(size.width, size.height) * 0.38;
    final cx = size.width / 2, cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);

    _drawFloor(canvas, scale);
    _drawWalls(canvas, scale);
    _drawOccupants(canvas, scale);

    canvas.restore();
  }

  void _drawFloor(Canvas canvas, double scale) {
    final floorPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.5);
    final path = Path();

    final corners = [
      Vec3(-1.5, -0.05, -1.5),
      Vec3(1.5, -0.05, -1.5),
      Vec3(1.5, -0.05, 1.5),
      Vec3(-1.5, -0.05, 1.5),
    ];
    final projected = corners
        .map((v) => proj.project(v, rotY: rotY, rotX: rotX, zoom: scale))
        .toList();

    path.moveTo(projected[0].dx, projected[0].dy);
    for (int i = 1; i < 4; i++) {
      path.lineTo(projected[i].dx, projected[i].dy);
    }
    path.close();
    canvas.drawPath(path, floorPaint);

    for (int i = -6; i <= 6; i++) {
      final alpha = (1 - i.abs() / 7.0) * 0.08;
      final gridPaint = Paint()
        ..color = const Color(0xFF00BCD4).withValues(alpha: alpha)
        ..strokeWidth = 0.5;

      final p1 = proj.project(Vec3(i * 0.25, -0.05, -1.5), rotY: rotY, rotX: rotX, zoom: scale);
      final p2 = proj.project(Vec3(i * 0.25, -0.05, 1.5), rotY: rotY, rotX: rotX, zoom: scale);
      canvas.drawLine(p1, p2, gridPaint);

      final p3 = proj.project(Vec3(-1.5, -0.05, i * 0.25), rotY: rotY, rotX: rotX, zoom: scale);
      final p4 = proj.project(Vec3(1.5, -0.05, i * 0.25), rotY: rotY, rotX: rotX, zoom: scale);
      canvas.drawLine(p3, p4, gridPaint);
    }
  }

  void _drawWalls(Canvas canvas, double scale) {
    final wallPaint = Paint()
      ..color = const Color(0xFF00BCD4).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    final wallBorderPaint = Paint()
      ..color = const Color(0xFF00BCD4).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final wallDefs = [
      [Vec3(-1.5, 0, -1.5), Vec3(1.5, 0, -1.5), Vec3(1.5, 1.8, -1.5), Vec3(-1.5, 1.8, -1.5)],
      [Vec3(1.5, 0, -1.5), Vec3(1.5, 0, 1.5), Vec3(1.5, 1.8, 1.5), Vec3(1.5, 1.8, -1.5)],
      [Vec3(-1.5, 0, 1.5), Vec3(1.5, 0, 1.5), Vec3(1.5, 1.8, 1.5), Vec3(-1.5, 1.8, 1.5)],
    ];

    for (final wall in wallDefs) {
      final projected =
          wall.map((v) => proj.project(v, rotY: rotY, rotX: rotX, zoom: scale)).toList();
      final path = Path();
      path.moveTo(projected[0].dx, projected[0].dy);
      for (int i = 1; i < 4; i++) {
        path.lineTo(projected[i].dx, projected[i].dy);
      }
      path.close();
      canvas.drawPath(path, wallPaint);
      canvas.drawPath(path, wallBorderPaint);
    }
  }

  void _drawOccupants(Canvas canvas, double scale) {
    for (final occ in occupants) {
      final pos = proj.project(occ.position, rotY: rotY, rotX: rotX, zoom: scale);
      final p = Mat4.rotationX(rotX).transform(Mat4.rotationY(rotY).transform(occ.position));
      final depth = p.z;
      final radius = (12 - depth * 1.5).clamp(5.0, 18.0);
      final alpha = (1 - depth / 6).clamp(0.2, 0.9);

      final glowPaint = Paint()
        ..color = occ.color.withValues(alpha: alpha * 0.15)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(pos, radius * 3, glowPaint);

      final bodyPaint = Paint()
        ..color = occ.color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius * 1.5, bodyPaint);

      final corePaint = Paint()
        ..color = occ.color.withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius * 0.6, corePaint);

      final pulse = sin(time * 4 + occ.phase) * 0.5 + 0.5;
      final pulsePaint = Paint()
        ..color = occ.color.withValues(alpha: pulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(pos, radius * 2 + pulse * 5, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoomScenePainter old) => true;
}
