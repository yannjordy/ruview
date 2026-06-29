import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InsightSeverity { info, warning, critical }
enum InsightCategory { health, safety, activity, environment, trend }

class Insight {
  final String id;
  final String title;
  final String description;
  final InsightSeverity severity;
  final InsightCategory category;
  final double? value;
  final String? unit;
  final DateTime timestamp;
  final bool dismissed;

  Insight({
    required this.id,
    required this.title,
    required this.description,
    this.severity = InsightSeverity.info,
    this.category = InsightCategory.health,
    this.value,
    this.unit,
    DateTime? timestamp,
    this.dismissed = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Insight copyWith({bool? dismissed}) => Insight(
        id: id,
        title: title,
        description: description,
        severity: severity,
        category: category,
        value: value,
        unit: unit,
        timestamp: timestamp,
        dismissed: dismissed ?? this.dismissed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'severity': severity.name,
        'category': category.name,
        'value': value,
        'unit': unit,
        'timestamp': timestamp.toIso8601String(),
        'dismissed': dismissed,
      };
}

class InsightEngine {
  static final InsightEngine _instance = InsightEngine._();
  factory InsightEngine() => _instance;
  InsightEngine._();

  final List<Insight> _insights = [];
  final _insightHistory = <Insight>[];
  double? _lastBr;
  int? _lastHr;
  double _brAccum = 0;
  int _brCount = 0;
  bool _initialized = false;

  List<Insight> get activeInsights =>
      _insights.where((i) => !i.dismissed).toList();

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('insight_history');
    if (saved != null) {
      try {
        final list = jsonDecode(saved) as List;
        for (final item in list) {
          _insightHistory.add(Insight(
            id: item['id'],
            title: item['title'],
            description: item['description'],
            severity: InsightSeverity.values.byName(item['severity']),
            category: InsightCategory.values.byName(item['category']),
            value: item['value']?.toDouble(),
            unit: item['unit'],
            timestamp: DateTime.parse(item['timestamp']),
            dismissed: item['dismissed'] ?? false,
          ));
        }
      } catch (_) {}
    }
    _initialized = true;
  }

  /// Analyse une lecture vitale et génère des insights si pertinent
  void ingestVitals(double? breathingRate, int? heartRate,
      {double? brConfidence, double? hrConfidence}) {
    if (breathingRate != null) {
      _brAccum += breathingRate;
      _brCount++;
      _lastBr = breathingRate;

      if (breathingRate < 8 && (brConfidence ?? 1) > 0.7) {
        _addInsight(Insight(
          id: 'bradypnea_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Respiration anormalement lente',
          description:
              'La fréquence respiratoire est descendue à ${breathingRate.toStringAsFixed(1)} BPM, '
              'ce qui est sous le seuil normal (12-20 BPM). Possible apnée du sommeil.',
          severity: InsightSeverity.warning,
          category: InsightCategory.health,
          value: breathingRate,
          unit: 'BPM',
        ));
      }

      if (breathingRate > 24 && (brConfidence ?? 1) > 0.7) {
        _addInsight(Insight(
          id: 'tachypnea_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Respiration rapide détectée',
          description:
              '${breathingRate.toStringAsFixed(1)} respirations/min — au-dessus de la normale. '
              'Stress, fièvre ou activité physique récente possible.',
          severity: InsightSeverity.info,
          category: InsightCategory.health,
          value: breathingRate,
          unit: 'BPM',
        ));
      }
    }

    if (heartRate != null) {
      _lastHr = heartRate;

      if (heartRate > 100 && (hrConfidence ?? 1) > 0.7) {
        _addInsight(Insight(
          id: 'tachycardia_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Rythme cardiaque élevé',
          description:
              '$heartRate BPM — au-dessus de la normale au repos (60-100). '
              'Surveiller si persistant.',
          severity: InsightSeverity.info,
          category: InsightCategory.health,
          value: heartRate.toDouble(),
          unit: 'BPM',
        ));
      }

      if (heartRate < 50 && (hrConfidence ?? 1) > 0.7) {
        _addInsight(Insight(
          id: 'bradycardia_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Rythme cardiaque lent',
          description:
              '$heartRate BPM — en dessous de 50. Peut être normal chez les sportifs, '
              'mais à surveiller si accompagné d\'autres symptômes.',
          severity: InsightSeverity.info,
          category: InsightCategory.health,
          value: heartRate.toDouble(),
          unit: 'BPM',
        ));
      }
    }
  }

  /// Analyse une pièce et génère des insights contextuels
  List<Insight> analyzeRoom(String roomName, int occupantCount,
      {double? breathingRate, int? heartRate, double? temperature}) {
    final results = <Insight>[];

    if (occupantCount > 3) {
      results.add(Insight(
        id: 'overcrowding_$roomName',
        title: 'Pièce très fréquentée',
        description:
            '$occupantCount personnes détectées dans $roomName — '
            'forte activité dans la pièce.',
        severity: InsightSeverity.info,
        category: InsightCategory.activity,
        value: occupantCount.toDouble(),
        unit: 'personnes',
      ));
    }

    if (occupantCount == 0 && _lastBr != null) {
      final hoursSinceOccupied = DateTime.now()
              .difference(_lastOccupiedTime ?? DateTime.now())
              .inHours;
      if (hoursSinceOccupied > 4) {
        results.add(Insight(
          id: 'inactivity_$roomName',
          title: 'Pièce vide depuis longtemps',
          description:
              'Aucun mouvement dans $roomName depuis $hoursSinceOccupied h.',
          severity: InsightSeverity.info,
          category: InsightCategory.activity,
        ));
      }
    }

    if (occupantCount > 0) {
      _lastOccupiedTime = DateTime.now();
    }

    return results;
  }

  DateTime? _lastOccupiedTime;

  /// Génère un résumé quotidien
  Insight dailySummary() {
    final avgBr = _brCount > 0 ? _brAccum / _brCount : 0.0;
    final insightCount = _insightHistory.length;

    String title, description;
    if (insightCount > 5) {
      title = 'Activité inhabituelle aujourd\'hui';
      description =
          '$insightCount événements détectés — plus que la moyenne. '
          'Fréquence respiratoire moyenne : ${avgBr.toStringAsFixed(1)} BPM.';
    } else {
      title = 'Journée calme';
      description =
          'Seulement $insightCount événements notables. '
          'Rythme respiratoire moyen : ${avgBr.toStringAsFixed(1)} BPM.';
    }

    return Insight(
      id: 'daily_${DateTime.now().toIso8601String().substring(0, 10)}',
      title: title,
      description: description,
      severity: InsightSeverity.info,
      category: InsightCategory.trend,
      value: avgBr,
      unit: 'BPM moyen',
    );
  }

  /// Calcule un score de risque de chute (0-100)
  double fallRiskScore({
    double? heartRateVariability,
    bool? recentFall,
    int? age,
  }) {
    double score = 0;
    if (recentFall == true) score += 40;
    if (age != null && age > 75) score += 20;
    if (heartRateVariability != null && heartRateVariability > 0.1) {
      score += 15;
    }
    // Variations d'activité nocturne
    if (_lastHr != null && _lastHr! > 90) score += 10;
    return score.clamp(0, 100);
  }

  void _addInsight(Insight insight) {
    // Évite les doublons similaires dans les 5 minutes
    final exists = _insights.any((i) =>
        i.title == insight.title &&
        i.timestamp.difference(insight.timestamp).abs().inMinutes < 5);
    if (exists) return;

    _insights.add(insight);
    _insightHistory.add(insight);

    // Sauvegarde
    _saveHistory();

    debugPrint('Insight: [${insight.severity}] ${insight.title}');
  }

  void dismissInsight(String id) {
    final idx = _insights.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _insights[idx] = _insights[idx].copyWith(dismissed: true);
      _saveHistory();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = _insightHistory.reversed.take(200).toList();
    await prefs.setString(
        'insight_history', jsonEncode(recent.map((i) => i.toJson()).toList()));
  }

  void dispose() {}
}
