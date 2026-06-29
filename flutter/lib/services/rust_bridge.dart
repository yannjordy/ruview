import 'dart:math';

class BridgeOutput {
  final double breathingRate;
  final double brConfidence;
  final int heartRate;
  final double hrConfidence;
  BridgeOutput({
    this.breathingRate = 16.0,
    this.brConfidence = 0.85,
    this.heartRate = 72,
    this.hrConfidence = 0.80,
  });

  bool get valid => brConfidence > 0.3 || hrConfidence > 0.3;
}

class PresenceOutput {
  final bool present;
  final double confidence;
  PresenceOutput({this.present = false, this.confidence = 0.0});
}

class ProcessedCsi {
  final List<List<double>> smoothed;
  final double meanAmplitude;
  final int subcarrierCount;
  final int antennaCount;
  ProcessedCsi({
    required this.smoothed,
    this.meanAmplitude = 0.0,
    this.subcarrierCount = 0,
    this.antennaCount = 0,
  });
}

class RustBridge {
  bool _nativeAvailable = false;
  final Random _rng = Random(42);

  bool get isNative => _nativeAvailable;

  Future<bool> init() async {
    try {
      // Tentative de chargement natif (silencieux si échoue)
      // final lib = NativeLibrary.load('aetheris_bridge');
      _nativeAvailable = false; // mis à true quand flutter_rust_bridge_codegen généré
      return _nativeAvailable;
    } catch (_) {
      _nativeAvailable = false;
      return false;
    }
  }

  Future<BridgeOutput> extractVitals(String frameJson) async {
    if (_nativeAvailable) {
      // return await api.extractVitals(frameJson);
    }
    // Mock : génère des vitaux réalistes
    final br = 15.0 + sin(_rng.nextDouble() * 6.28) * 2.0 + _rng.nextGaussian() * 0.3;
    final hr = 72 + sin(_rng.nextDouble() * 6.28 + 1) * 5 + _rng.nextGaussian() * 1;
    return BridgeOutput(
      breathingRate: br.clamp(8.0, 30.0),
      brConfidence: (0.85 + _rng.nextGaussian() * 0.05).clamp(0.3, 0.98),
      heartRate: hr.round().clamp(45, 120),
      hrConfidence: (0.80 + _rng.nextGaussian() * 0.05).clamp(0.3, 0.98),
    );
  }

  Future<String> calibrateRoom(String roomId, int durationSecs) async {
    if (_nativeAvailable) {
      // return await api.calibrateRoom(roomId, durationSecs);
    }
    await Future.delayed(Duration(seconds: durationSecs));
    return "Room '$roomId' calibrated (${durationSecs}s)";
  }

  Future<PresenceOutput> detectPresence(String frameJson) async {
    if (_nativeAvailable) {
      // return await api.detectPresence(frameJson);
    }
    final pv = _rng.nextDouble() * 0.1;
    return PresenceOutput(
      present: pv > 0.02,
      confidence: pv.clamp(0.0, 1.0),
    );
  }

  Future<ProcessedCsi> processCsi(List<List<double>> subcarriers) async {
    if (_nativeAvailable) {
      // return await api.processCsi(subcarriers);
    }
    final smoothed = subcarriers
        .map((row) => row.map((v) => v + _rng.nextGaussian() * 0.01).toList())
        .toList();
    final all = smoothed.expand((r) => r);
    final mean = all.isEmpty ? 0.0 : all.reduce((a, b) => a + b) / all.length;
    return ProcessedCsi(
      smoothed: smoothed,
      meanAmplitude: mean,
      subcarrierCount: subcarriers.first.length,
      antennaCount: subcarriers.length,
    );
  }
}
