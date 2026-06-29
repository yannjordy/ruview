import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aetheris/core/models.dart';
import 'package:aetheris/core/theme.dart';
import 'package:aetheris/core/api_types.dart';
import 'package:aetheris/services/api_service.dart';
import 'package:aetheris/widgets/vitals_card.dart';
import 'package:aetheris/widgets/room_card.dart';
import 'package:aetheris/widgets/sensor_grid.dart';
import 'package:aetheris/widgets/breathing_indicator.dart';
import 'package:aetheris/widgets/signal_particles.dart';
import 'package:aetheris/widgets/pose_renderer.dart';
import 'package:aetheris/widgets/room_scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VitalsCard', () {
    testWidgets('affiche respiration et coeur', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: VitalsCard(
            breathingRate: 16.5,
            heartRate: 72,
            brConfidence: 0.9,
            hrConfidence: 0.85,
          ),
        ),
      ));
      expect(find.text('16.5 BPM'), findsOneWidget);
      expect(find.text('72 BPM'), findsOneWidget);
      expect(find.text('Respiration'), findsOneWidget);
    });

    testWidgets('affiche -- quand pas de données', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: const VitalsCard()),
      ));
      expect(find.text('--'), findsNWidgets(2));
    });
  });

  group('RoomCard', () {
    testWidgets('affiche les infos pièce', (tester) async {
      final room = Room(
        id: 'salon',
        name: 'Salon',
        status: DeviceStatus.online,
        occupantCount: 2,
        breathingRate: 15.2,
        heartRate: 70,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: RoomCard(room: room)),
      ));

      expect(find.text('Salon'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('15.2 BPM'), findsOneWidget);
    });

    testWidgets('affiche offline', (tester) async {
      final room = Room(id: 'garage', name: 'Garage', status: DeviceStatus.offline);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: RoomCard(room: room)),
      ));
      expect(find.text('Garage'), findsOneWidget);
    });
  });

  group('SensorGrid', () {
    testWidgets('affiche tous les capteurs', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: const SensorGrid()),
      ));
      expect(find.text('Présence'), findsOneWidget);
      expect(find.text('Respiration'), findsOneWidget);
      expect(find.text('Chute'), findsOneWidget);
    });
  });

  group('BreathingIndicator', () {
    testWidgets('se rend sans erreur', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BreathingIndicator(breathingRate: 16.0, confidence: 0.9),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BreathingIndicator), findsOneWidget);
    });
  });

  group('SignalParticles', () {
    testWidgets('se rend sans erreur', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 100,
            child: SignalParticles(particleCount: 5),
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SignalParticles), findsOneWidget);
    });
  });

  group('Pose3DRenderer', () {
    testWidgets('se rend sans erreur', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const SizedBox(
            height: 200,
            child: Pose3DRenderer(),
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Pose3DRenderer), findsOneWidget);
    });
  });

  group('RoomScene3D', () {
    testWidgets('se rend sans erreur', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const SizedBox(
            height: 200,
            child: RoomScene3D(occupantCount: 2),
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RoomScene3D), findsOneWidget);
    });
  });

  group('RoomUpdate fromJson', () {
    test('parse correctement', () {
      final json = {
        'id': 'bureau',
        'name': 'Bureau',
        'status': 'online',
        'occupant_count': 1,
        'breathing_rate': 16.1,
        'heart_rate': 78,
        'last_updated': 1700000000000,
      };
      final ru = RoomUpdate.fromJson(json);
      expect(ru.id, 'bureau');
      expect(ru.name, 'Bureau');
      expect(ru.status, DeviceStatus.online);
      expect(ru.occupantCount, 1);
      expect(ru.breathingRate, 16.1);
      expect(ru.heartRate, 78);
    });

    test('parse status offline', () {
      final json = {'id': 'x', 'name': 'X', 'status': 'offline', 'last_updated': 0};
      final ru = RoomUpdate.fromJson(json);
      expect(ru.status, DeviceStatus.offline);
    });

    test('toRoom conversion', () {
      final json = {
        'id': 'salon',
        'name': 'Salon',
        'status': 'online',
        'occupant_count': 2,
        'last_updated': 0,
      };
      final ru = RoomUpdate.fromJson(json);
      final room = ru.toRoom();
      expect(room.id, 'salon');
      expect(room.name, 'Salon');
      expect(room.status, DeviceStatus.online);
    });
  });

  group('ApiResult', () {
    test('success', () {
      final r = ApiResult.success(42);
      expect(r.isSuccess, true);
      expect(r.isError, false);
      expect(r.data, 42);
    });
    test('failure', () {
      final r = ApiResult<int>.failure(ApiError.network, message: 'timeout');
      expect(r.isSuccess, false);
      expect(r.isError, true);
      expect(r.error, ApiError.network);
      expect(r.message, 'timeout');
    });
  });

  group('Theme', () {
    test('sensorColors contient toutes les clés', () {
      expect(AppTheme.sensorColors, containsPair('presence', anything));
      expect(AppTheme.sensorColors, containsPair('breathing', anything));
      expect(AppTheme.sensorColors, containsPair('heartrate', anything));
      expect(AppTheme.sensorColors, containsPair('pose', anything));
      expect(AppTheme.sensorColors, containsPair('fall', anything));
      expect(AppTheme.sensorColors, containsPair('sleep', anything));
    });
  });
}
