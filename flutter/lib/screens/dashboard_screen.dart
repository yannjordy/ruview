import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/vitals_card.dart';
import '../widgets/room_card.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/pose_renderer.dart';
import '../widgets/room_scene.dart';
import '../widgets/signal_particles.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  List<Room> _rooms = [];
  VitalsReading? _globalVitals;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiService>();
    api.connectWebSocket();
    _loadData();
    _timer = Timer.periodic(AppConstants.sensorPollInterval, (_) => _loadData());
  }

  Future<void> _loadData() async {
    final api = context.read<ApiService>();
    final rooms = await api.getRooms();
    final vitals = await api.getRoomVitals('all');
    if (mounted) {
      setState(() {
        _rooms = rooms;
        _globalVitals = vitals;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi, color: Color(0xFF00BCD4)),
            const SizedBox(width: 8),
            Text('Aetheris', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(l),
                  const SizedBox(height: 16),
                  _build3DScene(context, l),
                  const SizedBox(height: 16),
                  if (_globalVitals != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: VitalsCard(
                        breathingRate: _globalVitals!.breathingRate,
                        heartRate: _globalVitals!.heartRate,
                        brConfidence: _globalVitals!.brConfidence,
                        hrConfidence: _globalVitals!.hrConfidence,
                      ),
                    ),
                  Text(l.t('rooms.title'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._rooms.map((room) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RoomCard(
                          room: room,
                          onTap: () => Navigator.pushNamed(context, '/room',
                              arguments: room.id),
                        ),
                      )),
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 60,
                    child: SignalParticles(particleCount: 20),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    final online = _rooms.where((r) => r.status == DeviceStatus.online).length;
    final totalPresence =
        _rooms.fold<int>(0, (s, r) => s + r.occupantCount);
    return Row(
      children: [
        _StatCard(
          icon: Icons.wifi_tethering,
          label: l.t('dashboard.nodes_online'),
          value: '$online/${_rooms.length}',
          color: const Color(0xFF66BB6A),
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.people,
          label: l.t('dashboard.occupants'),
          value: '$totalPresence',
          color: const Color(0xFF42A5F5),
        ),
      ],
    );
  }

  Widget _build3DScene(BuildContext context, AppLocalizations l) {
    final totalPresence = _rooms.fold<int>(0, (s, r) => s + r.occupantCount);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(l.t('dashboard.live_view'),
                style: Theme.of(context).textTheme.titleMedium),
          ),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: RoomScene3D(
                      occupantCount: totalPresence,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: Colors.white10,
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Pose3DRenderer(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0),
                  const Color(0xFF00BCD4).withValues(alpha: 0.3),
                  const Color(0xFF00BCD4).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      )),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
