import 'package:flutter/material.dart';
import '../core/theme.dart';

class VitalsCard extends StatelessWidget {
  final double? breathingRate;
  final int? heartRate;
  final double? brConfidence;
  final double? hrConfidence;

  const VitalsCard({
    super.key,
    this.breathingRate,
    this.heartRate,
    this.brConfidence,
    this.hrConfidence,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Vital(
              icon: Icons.air,
              label: 'Respiration',
              value: breathingRate != null
                  ? '${breathingRate!.toStringAsFixed(1)} BPM'
                  : '--',
              color: AppTheme.sensorColors['breathing']!,
              confidence: brConfidence,
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.white10,
            ),
            _Vital(
              icon: Icons.favorite,
              label: 'Cœur',
              value:
                  heartRate != null ? '${heartRate} BPM' : '--',
              color: AppTheme.sensorColors['heartrate']!,
              confidence: hrConfidence,
            ),
          ],
        ),
      ),
    );
  }
}

class _Vital extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? confidence;

  const _Vital({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  )),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  )),
          if (confidence != null)
            Text('${(confidence! * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                    )),
        ],
      ),
    );
  }
}
