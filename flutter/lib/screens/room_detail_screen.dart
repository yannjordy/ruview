import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/csi_chart.dart';
import '../widgets/vitals_card.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/pose_renderer.dart';
import '../widgets/room_scene.dart';
import '../widgets/breathing_indicator.dart';
import '../widgets/signal_particles.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late String _roomId;
  Room? _room;
  VitalsReading? _vitals;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _roomId = ModalRoute.of(context)!.settings.arguments as String;
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    final api = context.read<ApiService>();
    final rooms = await api.getRooms();
    final room = rooms.where((r) => r.id == _roomId).firstOrNull;
    final vitals = await api.getRoomVitals(_roomId);
    if (mounted) {
      setState(() {
        _room = room;
        _vitals = vitals;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = _room?.name ?? _roomId;
    final status = _room?.status ?? DeviceStatus.offline;
    final hasOccupants = (_room?.occupantCount ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.pushNamed(context, '/calibrate',
                arguments: _roomId),
            tooltip: l.t('sensor.calibrate'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRoom,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusChip(status, l),
            const SizedBox(height: 16),
            _build3DScene(context, hasOccupants),
            const SizedBox(height: 16),
            if (_vitals != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: VitalsCard(
                  breathingRate: _vitals!.breathingRate,
                  heartRate: _vitals!.heartRate,
                  brConfidence: _vitals!.brConfidence,
                  hrConfidence: _vitals!.hrConfidence,
                ),
              ),
            _buildBreathingSection(context, l),
            const SizedBox(height: 16),
            Text(l.t('sensor.csi_signal'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(8),
                child: const CsiChart(),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.t('rooms.sensors'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const SensorGrid(),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: SignalParticles(particleCount: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DScene(BuildContext context, bool hasOccupants) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text('Visualisation 3D',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  hasOccupants ? '● Détection active' : '○ Aucun occupant',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasOccupants
                        ? const Color(0xFF66BB6A)
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: RoomScene3D(
                      occupantCount: _room?.occupantCount ?? 0,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: Colors.white10,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: hasOccupants
                        ? const Pose3DRenderer()
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sensor_occupied,
                                    size: 40, color: Colors.white24),
                                const SizedBox(height: 8),
                                Text('En attente...',
                                    style: TextStyle(color: Colors.white24)),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingSection(BuildContext context, AppLocalizations l) {
    final br = _vitals?.breathingRate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            BreathingIndicator(
              width: 80,
              height: 80,
              breathingRate: br,
              confidence: _vitals?.brConfidence,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.t('dashboard.respiration'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    br != null
                        ? '${br.toStringAsFixed(1)} respirations/min'
                        : 'Aucune donnée',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: br != null
                              ? const Color(0xFF42A5F5)
                              : Colors.white38,
                        ),
                  ),
                  if (_vitals?.brConfidence != null)
                    Text(
                      'Fiabilité : ${(_vitals!.brConfidence! * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(DeviceStatus status, AppLocalizations l) {
    final (color, label) = switch (status) {
      DeviceStatus.online => (const Color(0xFF66BB6A), l.t('sensor.online')),
      DeviceStatus.offline => (const Color(0xFFEF5350), l.t('sensor.offline')),
      DeviceStatus.calibrating =>
        (const Color(0xFFFFCA28), l.t('sensor.calibrating')),
      DeviceStatus.error => (const Color(0xFFFF7043), l.t('sensor.error')),
    };
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
