import 'package:flutter/material.dart';
import '../core/theme.dart';

class SensorGrid extends StatelessWidget {
  const SensorGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SensorChip(
          icon: Icons.wifi_tethering,
          label: 'Présence',
          color: AppTheme.sensorColors['presence']!,
          active: true,
        ),
        _SensorChip(
          icon: Icons.air,
          label: 'Respiration',
          color: AppTheme.sensorColors['breathing']!,
          active: true,
        ),
        _SensorChip(
          icon: Icons.favorite,
          label: 'Rythme cardiaque',
          color: AppTheme.sensorColors['heartrate']!,
          active: false,
        ),
        _SensorChip(
          icon: Icons.accessibility,
          label: 'Pose',
          color: AppTheme.sensorColors['pose']!,
          active: false,
        ),
        _SensorChip(
          icon: Icons.sensor_occupied,
          label: 'Chute',
          color: AppTheme.sensorColors['fall']!,
          active: true,
        ),
        _SensorChip(
          icon: Icons.bedtime,
          label: 'Sommeil',
          color: AppTheme.sensorColors['sleep']!,
          active: false,
        ),
      ],
    );
  }
}

class _SensorChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  const _SensorChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: active,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: active ? color : Colors.white38),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : Colors.white54,
              )),
        ],
      ),
      onSelected: null,
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
    );
  }
}
