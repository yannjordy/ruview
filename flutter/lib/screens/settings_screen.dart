import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(Locale)? onLocaleChanged;

  const SettingsScreen({super.key, this.onLocaleChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  String _language = 'fr';
  bool _mqttEnabled = true;
  bool _homeAssistantEnabled = true;
  double _sensitivity = 0.7;
  bool _recordingEnabled = false;
  bool _loading = true;
  String? _saveFeedback;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? true;
      _language = prefs.getString('language') ?? 'fr';
      _mqttEnabled = prefs.getBool('mqtt_enabled') ?? true;
      _homeAssistantEnabled = prefs.getBool('ha_enabled') ?? true;
      _sensitivity = prefs.getDouble('sensitivity') ?? 0.7;
      _recordingEnabled = prefs.getBool('recording_enabled') ?? false;
      _loading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);

    final api = context.read<ApiService>();
    await api.setConfig(key, value);

    if (!mounted) return;
    setState(() {
      _saveFeedback = '✓ Sauvegardé';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saveFeedback = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l.t('settings.title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('settings.title')),
        actions: [
          if (_saveFeedback != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(_saveFeedback!,
                    style: const TextStyle(
                        color: Color(0xFF66BB6A), fontSize: 12)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(l.t('settings.general')),
          SwitchListTile(
            title: Text(l.t('settings.dark_mode')),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveSetting('dark_mode', v);
            },
          ),
          ListTile(
            title: Text(l.t('settings.language')),
            subtitle: Text(_language == 'fr' ? 'Français' : 'English'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fr', label: Text('FR')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {_language},
              onSelectionChanged: (v) {
                setState(() => _language = v.first);
                _saveSetting('language', v.first);
                widget.onLocaleChanged?.call(Locale(v.first));
              },
            ),
          ),
          const Divider(),
          _buildSection(l.t('settings.integrations')),
          SwitchListTile(
            title: Text(l.t('settings.mqtt')),
            subtitle: Text('${AppConstants.mqttBroker}:${AppConstants.mqttPort}'),
            value: _mqttEnabled,
            onChanged: (v) {
              setState(() => _mqttEnabled = v);
              _saveSetting('mqtt_enabled', v);
            },
          ),
          SwitchListTile(
            title: const Text('Home Assistant'),
            subtitle: Text(l.t('settings.home_assistant_desc')),
            value: _homeAssistantEnabled,
            onChanged: (v) {
              setState(() => _homeAssistantEnabled = v);
              _saveSetting('ha_enabled', v);
            },
          ),
          const Divider(),
          _buildSection(l.t('settings.detection')),
          ListTile(
            title: Text(l.t('settings.sensitivity')),
            subtitle: Slider(
              value: _sensitivity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(_sensitivity * 100).round()}%',
              onChanged: (v) => setState(() => _sensitivity = v),
              onChangeEnd: (v) => _saveSetting('sensitivity', v),
            ),
          ),
          SwitchListTile(
            title: Text(l.t('settings.recording')),
            subtitle: Text(l.t('settings.recording_desc')),
            value: _recordingEnabled,
            onChanged: (v) {
              setState(() => _recordingEnabled = v);
              _saveSetting('recording_enabled', v);
            },
          ),
          const Divider(),
          _buildSection(l.t('settings.about')),
          ListTile(
            title: const Text('Aetheris'),
            subtitle: Text('${l.t('settings.version')} ${AppConstants.version}'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white38),
            title: const Text('Serveur'),
            subtitle: Text(AppConstants.apiBaseUrl,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Démarrez le serveur : python scripts/mock-server.py',
              style: TextStyle(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.6),
                  fontSize: 11,
                  fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: const Color(0xFF00BCD4))),
    );
  }
}
