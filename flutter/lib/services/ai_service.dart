import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'insight_engine.dart';

enum AiProvider { none, openai, anthropic, ollama }

class AiConfig {
  final AiProvider provider;
  final String apiKey;
  final String model;
  final String? baseUrl;

  AiConfig({
    this.provider = AiProvider.none,
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
    this.baseUrl,
  });

  static AiConfig get defaultConfig => AiConfig();

  static const storageKey = 'ai_config';
}

class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  AiConfig _config = AiConfig.defaultConfig;
  bool _initialized = false;

  bool get isAvailable => _config.provider != AiProvider.none;
  AiConfig get config => _config;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AiConfig.storageKey);
    if (saved != null) {
      try {
        final data = jsonDecode(saved);
        _config = AiConfig(
          provider: AiProvider.values.byName(data['provider'] ?? 'none'),
          apiKey: data['api_key'] ?? '',
          model: data['model'] ?? 'gpt-4o-mini',
          baseUrl: data['base_url'],
        );
      } catch (_) {}
    }
    _initialized = true;
  }

  Future<void> updateConfig(AiConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AiConfig.storageKey, jsonEncode({
      'provider': config.provider.name,
      'api_key': config.apiKey,
      'model': config.model,
      'base_url': config.baseUrl,
    }));
  }

  /// Analyse un texte court (description d'événement, tendance) et retourne un insight enrichi.
  /// Sans LLM, retourne l'analyse locale. Avec LLM, enrichit le résultat.
  Future<String> analyzeEvent(String eventDescription,
      {Map<String, dynamic>? context}) async {
    if (!isAvailable) return eventDescription;

    try {
      final prompt = _buildPrompt(eventDescription, context);
      final response = await _callLlm(prompt);
      return response.isNotEmpty ? response : eventDescription;
    } catch (e) {
      debugPrint('AiService: LLM call failed ($e)');
      return eventDescription;
    }
  }

  /// Génère un titre d'insight amélioré
  Future<String> enhanceTitle(String rawTitle) async {
    if (!isAvailable) return rawTitle;
    try {
      final response = await _callLlm(
          'Améliore ce titre d\'alerte pour un système de détection WiFi (concis, français) : "$rawTitle"');
      return response.isNotEmpty ? response : rawTitle;
    } catch (_) {
      return rawTitle;
    }
  }

  /// Détection de motifs anormaux dans les séries de valeurs
  Future<List<Insight>> analyzeVitalsHistory(
      List<double> breathingRates, List<int> heartRates) async {
    final insights = <Insight>[];
    if (breathingRates.length < 10) return insights;

    // Analyse locale (toujours active)
    final mean = breathingRates.reduce((a, b) => a + b) / breathingRates.length;
    final variance = breathingRates
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        breathingRates.length;
    final stdDev = variance <= 0 ? 0.0 : sqrt(variance);

    if (variance > 5.0) {
      insights.add(Insight(
        id: 'hrv_high_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Variabilité respiratoire élevée',
        description:
            'Écart-type de ${stdDev.toStringAsFixed(1)} BPM — '
            'variations respiratoires importantes. Possible agitation ou stress.',
        severity: InsightSeverity.info,
        category: InsightCategory.health,
        value: stdDev,
        unit: 'σ BPM',
      ));
    }

    // Analyse LLM si disponible
    if (isAvailable && breathingRates.length > 20) {
      final summary = await analyzeEvent(
        'Analyse ces fréquences respiratoires (BPM) sur les dernières minutes',
        context: {
          'values': breathingRates.take(30).toList(),
          'mean': mean.toStringAsFixed(1),
          'std_dev': stdDev.toStringAsFixed(2),
        },
      );
      if (summary.isNotEmpty && summary != 'Analyse ces fréquences...') {
        insights.add(Insight(
          id: 'llm_br_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Analyse IA',
          description: summary,
          severity: InsightSeverity.info,
          category: InsightCategory.trend,
        ));
      }
    }

    return insights;
  }

  // -- Interne LLM --

  String _buildPrompt(String event, Map<String, dynamic>? context) {
    var prompt = 'Tu es un expert en analyse de données de capteurs WiFi.'
        ' Réponds en une phrase concise (max 150 caractères) en français.\n'
        'Événement : $event\n';
    if (context != null) {
      prompt += 'Contexte : ${jsonEncode(context)}\n';
    }
    prompt += 'Analyse :';
    return prompt;
  }

  Future<String> _callLlm(String prompt) async {
    switch (_config.provider) {
      case AiProvider.openai:
        return _callOpenAi(prompt);
      case AiProvider.anthropic:
        return _callAnthropic(prompt);
      case AiProvider.ollama:
        return _callOllama(prompt);
      case AiProvider.none:
        return '';
    }
  }

  Future<String> _callOpenAi(String prompt) async {
    final url = _config.baseUrl ?? 'https://api.openai.com/v1/chat/completions';
    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer ${_config.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _config.model,
              'messages': [
                {'role': 'system', 'content': 'Réponds en français, concis, max 150 caractères.'},
                {'role': 'user', 'content': prompt},
              ],
              'max_tokens': 100,
              'temperature': 0.3,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices']?[0]?['message']?['content'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<String> _callAnthropic(String prompt) async {
    try {
      final res = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': _config.apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _config.model,
              'max_tokens': 100,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['content']?[0]?['text'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<String> _callOllama(String prompt) async {
    final url = _config.baseUrl ?? 'http://localhost:11434';
    try {
      final res = await http
          .post(
            Uri.parse('$url/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': _config.model,
              'prompt': prompt,
              'stream': false,
              'options': {'num_predict': 100, 'temperature': 0.3},
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['response'] ?? '';
      }
    } catch (_) {}
    return '';
  }
}


