import 'dart:math';
import 'package:flutter/material.dart';
import 'pose_3d_math.dart';

class PoseKeypoint3D {
  final String name;
  final Vec3 position;
  final double confidence;

  PoseKeypoint3D({required this.name, required this.position, this.confidence = 1.0});
}

class PoseSkeleton {
  final List<PoseKeypoint3D> keypoints;

  PoseSkeleton(this.keypoints);

  static const connections = [
    [0, 1], [0, 2], [1, 3], [2, 4],
    [5, 6], [5, 7], [7, 9], [6, 8], [8, 10],
    [5, 11], [6, 12], [11, 12],
    [11, 13], [13, 15], [12, 14], [14, 16],
  ];

  static const jointLabels = [
    'nez', 'œil G', 'œil D', 'oreille G', 'oreille D',
    'épaule G', 'épaule D', 'coude G', 'coude D', 'poignet G', 'poignet D',
    'hanche G', 'hanche D', 'genou G', 'genou D', 'cheville G', 'cheville D',
  ];

  factory PoseSkeleton.standing() {
    final kp = <PoseKeypoint3D>[
      PoseKeypoint3D(name: 'nose', position: Vec3(0, 1.6, 0)),
      PoseKeypoint3D(name: 'L_eye', position: Vec3(-0.15, 1.65, 0.1)),
      PoseKeypoint3D(name: 'R_eye', position: Vec3(0.15, 1.65, 0.1)),
      PoseKeypoint3D(name: 'L_ear', position: Vec3(-0.25, 1.6, 0.05)),
      PoseKeypoint3D(name: 'R_ear', position: Vec3(0.25, 1.6, 0.05)),
      PoseKeypoint3D(name: 'L_shoulder', position: Vec3(-0.3, 1.3, 0)),
      PoseKeypoint3D(name: 'R_shoulder', position: Vec3(0.3, 1.3, 0)),
      PoseKeypoint3D(name: 'L_elbow', position: Vec3(-0.4, 0.95, -0.1)),
      PoseKeypoint3D(name: 'R_elbow', position: Vec3(0.4, 0.95, -0.1)),
      PoseKeypoint3D(name: 'L_wrist', position: Vec3(-0.35, 0.65, -0.2)),
      PoseKeypoint3D(name: 'R_wrist', position: Vec3(0.35, 0.65, -0.2)),
      PoseKeypoint3D(name: 'L_hip', position: Vec3(-0.2, 0.8, 0)),
      PoseKeypoint3D(name: 'R_hip', position: Vec3(0.2, 0.8, 0)),
      PoseKeypoint3D(name: 'L_knee', position: Vec3(-0.2, 0.4, 0)),
      PoseKeypoint3D(name: 'R_knee', position: Vec3(0.2, 0.4, 0)),
      PoseKeypoint3D(name: 'L_ankle', position: Vec3(-0.2, 0.0, 0)),
      PoseKeypoint3D(name: 'R_ankle', position: Vec3(0.2, 0.0, 0)),
    ];
    return PoseSkeleton(kp);
  }

  PoseSkeleton interpolate(PoseSkeleton other, double t) {
    final kps = <PoseKeypoint3D>[];
    for (int i = 0; i < keypoints.length; i++) {
      kps.add(PoseKeypoint3D(
        name: keypoints[i].name,
        position: keypoints[i].position.lerp(other.keypoints[i].position, t),
        confidence: keypoints[i].confidence * (1 - t) + other.keypoints[i].confidence * t,
      ));
    }
    return PoseSkeleton(kps);
  }
}

class Pose3DRenderer extends StatefulWidget {
  final double width;
  final double height;

  const Pose3DRenderer({super.key, this.width = double.infinity, this.height = 200});

  @override
  State<Pose3DRenderer> createState() => _Pose3DRendererState();
}

class _Pose3DRendererState extends State<Pose3DRenderer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final Projection _proj = Projection(fov: 50, aspect: 1);
  final Random _rng = Random(42);
  final List<SmoothValue> _jointValues = [];
  PoseSkeleton _basePose = PoseSkeleton.standing();
  double _rotY = 0, _rotX = 0.15;
  double _breathPhase = 0;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    for (int i = 0; i < 17; i++) {
      for (int axis = 0; axis < 3; axis++) {
        _jointValues.add(SmoothValue(0, stiffness: 80, damping: 10));
      }
    }
    _generateRandomPose();
  }

  void _generateRandomPose() {
    final offset = Vec3(
      (_rng.nextDouble() - 0.5) * 0.3,
      (_rng.nextDouble() - 0.5) * 0.2,
      (_rng.nextDouble() - 0.5) * 0.3,
    );
    final target = PoseSkeleton(_basePose.keypoints.map((kp) {
      final jitter = Vec3(
        (_rng.nextDouble() - 0.5) * 0.4,
        (_rng.nextDouble() - 0.5) * 0.3,
        (_rng.nextDouble() - 0.5) * 0.4,
      );
      return PoseKeypoint3D(
        name: kp.name,
        position: kp.position + jitter + offset,
        confidence: 0.7 + _rng.nextDouble() * 0.3,
      );
    }).toList());

    for (int i = 0; i < 17; i++) {
      for (int axis = 0; axis < 3; axis++) {
        final idx = i * 3 + axis;
        final targetVal = _toList(target.keypoints[i].position)[axis];
        _jointValues[idx].target = targetVal;
      }
    }

    Future.delayed(const Duration(milliseconds: 2500 + _rng.nextInt(3000)), () {
      if (mounted) _generateRandomPose();
    });
  }

  List<double> _toList(Vec3 v) => [v.x, v.y, v.z];

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
        _breathPhase += dt * 0.00002;
        if (_breathPhase > 2 * pi) _breathPhase -= 2 * pi;

        for (final jv in _jointValues) {
          jv.update(dt / 1000000);
        }

        final kps = <PoseKeypoint3D>[];
        for (int i = 0; i < 17; i++) {
          final x = _jointValues[i * 3].current;
          final y = _jointValues[i * 3 + 1].current;
          final z = _jointValues[i * 3 + 2].current;
          final breathOffset = (i >= 5 && i <= 12) ? sin(_breathPhase) * 0.03 : 0.0;
          kps.add(PoseKeypoint3D(
            name: _basePose.keypoints[i].name,
            position: Vec3(x, y + breathOffset, z),
            confidence: 0.85 + sin(_breathPhase * 0.5 + i) * 0.1,
          ));
        }
        final skeleton = PoseSkeleton(kps);
        _rotY += dt * 0.0000003;

        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _Pose3DPainter(skeleton, _proj, _rotY, _rotX, _breathPhase),
        );
      },
    );
  }
}

class _Pose3DPainter extends CustomPainter {
  final PoseSkeleton skeleton;
  final Projection proj;
  final double rotY, rotX, breathPhase;

  _Pose3DPainter(this.skeleton, this.proj, this.rotY, this.rotX, this.breathPhase);

  @override
  void paint(Canvas canvas, Size size) {
    proj.aspect = size.width / size.height;
    final cx = size.width / 2, cy = size.height / 2;
    final scale = min(size.width, size.height) * 0.35;

    canvas.save();
    canvas.translate(cx, cy);

    _drawFloorGrid(canvas, size, scale);
    _drawSkeleton(canvas, scale);
    _drawParticles(canvas, size, scale);

    canvas.restore();
  }

  void _drawFloorGrid(Canvas canvas, Size size, double scale) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00BCD4).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (int i = -4; i <= 4; i++) {
      final p1 = proj.project(Vec3(i * 0.25, -0.05, -1), rotY: rotY, rotX: rotX, zoom: scale);
      final p2 = proj.project(Vec3(i * 0.25, -0.05, 1), rotY: rotY, rotX: rotX, zoom: scale);
      canvas.drawLine(p1, p2, gridPaint);
      final p3 = proj.project(Vec3(-1, -0.05, i * 0.25), rotY: rotY, rotX: rotX, zoom: scale);
      final p4 = proj.project(Vec3(1, -0.05, i * 0.25), rotY: rotY, rotX: rotX, zoom: scale);
      canvas.drawLine(p3, p4, gridPaint);
    }
  }

  void _drawSkeleton(Canvas canvas, double scale) {
    final kps = skeleton.keypoints;
    final projected = kps.map((kp) => proj.project(kp.position, rotY: rotY, rotX: rotX, zoom: scale)).toList();
    final depths = kps.map((kp) {
      final p = Mat4.rotationX(rotX).transform(Mat4.rotationY(rotY).transform(kp.position));
      return p.z;
    }).toList();

    final bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final conn in PoseSkeleton.connections) {
      final i = conn[0], j = conn[1];
      final ci = kps[i].confidence, cj = kps[j].confidence;
      if (ci < 0.3 || cj < 0.3) continue;

      final alpha = ((ci + cj) / 2 * 0.8).clamp(0.1, 0.8);
      final avgDepth = (depths[i] + depths[j]) / 2;
      final width = (2.5 - avgDepth * 0.3).clamp(1.0, 4.0);

      final glowPaint = Paint()
        ..color = const Color(0xFF00BCD4).withValues(alpha: alpha * 0.3)
        ..strokeWidth = width + 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(projected[i], projected[j], glowPaint);

      bonePaint.color = const Color(0xFF00BCD4).withValues(alpha: alpha);
      bonePaint.strokeWidth = width;
      canvas.drawLine(projected[i], projected[j], bonePaint);
    }

    for (int i = 0; i < kps.length; i++) {
      if (kps[i].confidence < 0.3) continue;
      final alpha = kps[i].confidence.clamp(0.3, 0.9);
      final depth = depths[i];
      final radius = (5 - depth * 0.5).clamp(3.0, 8.0);

      final glowPaint = Paint()
        ..color = const Color(0xFF26C6DA).withValues(alpha: alpha * 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(projected[i], radius * 2.5, glowPaint);

      final jointPaint = Paint()
        ..color = const Color(0xFF26C6DA).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(projected[i], radius, jointPaint);

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        projected[i] + const Offset(-1.5, -1.5),
        radius * 0.35,
        highlightPaint,
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size, double scale) {
    final rng = Random(42);
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final t = (breathPhase + i * 0.3) % (2 * pi);
      final px = sin(t * 2 + i) * 0.6;
      final py = 0.5 + cos(t + i * 0.5) * 0.6;
      final pz = cos(t * 1.5 + i * 0.7) * 0.4;

      final pos = proj.project(Vec3(px, py, pz), rotY: rotY, rotX: rotX, zoom: scale);
      final alpha = (sin(t) * 0.5 + 0.5) * 0.15;
      final r = (sin(t * 2 + i) * 0.5 + 0.5) * 2 + 1;

      particlePaint.color = const Color(0xFF00BCD4).withValues(alpha: alpha);
      canvas.drawCircle(pos, r, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Pose3DPainter old) => true;
}
