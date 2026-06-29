import 'dart:math';

class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);
  Vec3 operator +(Vec3 v) => Vec3(x + v.x, y + v.y, z + v.z);
  Vec3 operator -(Vec3 v) => Vec3(x - v.x, y - v.y, z - v.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);
  Vec3 operator /(double s) => Vec3(x / s, y / s, z / s);
  double get length => sqrt(x * x + y * y + z * z);
  Vec3 normalize() => this / length;
  Vec3 lerp(Vec3 other, double t) =>
      Vec3(x + (other.x - x) * t, y + (other.y - y) * t, z + (other.z - z) * t);

  static Vec3 fromList(List<double> l) => Vec3(l[0], l[1], l.length > 2 ? l[2] : 0);
}

class Mat4 {
  final List<double> data;
  Mat4(this.data) : assert(data.length == 16);

  factory Mat4.identity() => Mat4([
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]);

  factory Mat4.rotationX(double angle) {
    final c = cos(angle), s = sin(angle);
    return Mat4([
      1, 0, 0, 0,
      0, c, -s, 0,
      0, s, c, 0,
      0, 0, 0, 1,
    ]);
  }

  factory Mat4.rotationY(double angle) {
    final c = cos(angle), s = sin(angle);
    return Mat4([
      c, 0, s, 0,
      0, 1, 0, 0,
      -s, 0, c, 0,
      0, 0, 0, 1,
    ]);
  }

  Vec3 transform(Vec3 v) {
    return Vec3(
      data[0] * v.x + data[1] * v.y + data[2] * v.z + data[3],
      data[4] * v.x + data[5] * v.y + data[6] * v.z + data[7],
      data[8] * v.x + data[9] * v.y + data[10] * v.z + data[11],
    );
  }
}

class Projection {
  final double fov, aspect, near, far;
  Projection({this.fov = 60, this.aspect = 1, this.near = 0.1, this.far = 100});

  Offset project(Vec3 world, {double rotY = 0, double rotX = 0, double zoom = 1}) {
    var p = world;
    p = Mat4.rotationX(rotX).transform(p);
    p = Mat4.rotationY(rotY).transform(p);
    final f = 1 / tan(fov * pi / 180 / 2);
    final z = p.z + 5;
    if (z.abs() < 0.01) return Offset.zero;
    return Offset(p.x * f * aspect * zoom / z, -p.y * f * zoom / z);
  }
}

class SmoothValue {
  double _current, _target, _velocity = 0;
  final double stiffness, damping;

  SmoothValue(this._current, {this.stiffness = 120, this.damping = 12}) : _target = _current;

  set target(double t) => _target = t;
  double get target => _target;
  double get current => _current;

  double update(double dt) {
    final diff = _target - _current;
    final force = stiffness * diff - damping * _velocity;
    _velocity += force * dt;
    _current += _velocity * dt;
    if (diff.abs() < 0.001 && _velocity.abs() < 0.001) {
      _current = _target;
      _velocity = 0;
    }
    return _current;
  }
}
