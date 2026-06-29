import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/insight_engine.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onDismiss;

  const InsightCard({super.key, required this.insight, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (insight.severity) {
      InsightSeverity.critical => (Icons.warning, const Color(0xFFEF5350)),
      InsightSeverity.warning => (Icons.info_outline, const Color(0xFFFFCA28)),
      InsightSeverity.info => (Icons.insights, const Color(0xFF42A5F5)),
    };
    final categoryIcon = switch (insight.category) {
      InsightCategory.health => Icons.favorite,
      InsightCategory.safety => Icons.shield,
      InsightCategory.activity => Icons.directions_walk,
      InsightCategory.environment => Icons.home,
      InsightCategory.trend => Icons.trending_up,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(categoryIcon,
                          size: 12,
                          color: color.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          insight.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                  ),
                  if (insight.value != null && insight.unit != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${insight.value!.toStringAsFixed(1)} ${insight.unit}',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  Text(
                    _timeAgo(insight.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: Colors.white24,
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}
