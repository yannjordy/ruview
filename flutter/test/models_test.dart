import 'package:flutter_test/flutter_test.dart';
import 'package:aetheris/core/models.dart';

void main() {
  group('Room', () {
    test('creates room with defaults', () {
      final room = Room(id: 'salon', name: 'Salon');
      expect(room.id, 'salon');
      expect(room.name, 'Salon');
      expect(room.status, DeviceStatus.offline);
      expect(room.occupantCount, 0);
    });

    test('creates room with vitals', () {
      final room = Room(
        id: 'chambre',
        name: 'Chambre',
        status: DeviceStatus.online,
        occupantCount: 1,
        breathingRate: 16.5,
        heartRate: 72,
      );
      expect(room.breathingRate, 16.5);
      expect(room.heartRate, 72);
    });
  });

  group('VitalsReading', () {
    test('creates from json', () {
      final json = {
        'breathing_rate': 14.2,
        'heart_rate': 68,
        'hr_confidence': 0.85,
        'br_confidence': 0.92,
      };
      final vitals = VitalsReading.fromJson(json);
      expect(vitals.breathingRate, 14.2);
      expect(vitals.heartRate, 68);
    });
  });
}
