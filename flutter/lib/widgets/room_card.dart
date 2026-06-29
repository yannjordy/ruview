import 'package:flutter/material.dart';
import '../core/models.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomCard({super.key, required this.room, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon) = switch (room.status) {
      DeviceStatus.online => (const Color(0xFF66BB6A), Icons.wifi),
      DeviceStatus.offline => (const Color(0xFFEF5350), Icons.wifi_off),
      DeviceStatus.calibrating =>
        (const Color(0xFFFFCA28), Icons.running_with_errors),
      DeviceStatus.error => (const Color(0xFFFF7043), Icons.error),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (room.occupantCount > 0) ...[
                          const Icon(Icons.people, size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text('${room.occupantCount}',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 12),
                        ],
                        if (room.breathingRate != null) ...[
                          const Icon(Icons.air, size: 14, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text('${room.breathingRate!.toStringAsFixed(1)} BPM',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
