import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final api = context.read<ApiService>();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(l.t('settings.general')),
          SwitchListTile(
            title: Text(l.t('settings.dark_mode')),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
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
              onSelectionChanged: (v) => setState(() => _language = v.first),
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
              api.setConfig('mqtt_enabled', v);
            },
          ),
          SwitchListTile(
            title: const Text('Home Assistant'),
            subtitle: Text(l.t('settings.home_assistant_desc')),
            value: _homeAssistantEnabled,
            onChanged: (v) {
              setState(() => _homeAssistantEnabled = v);
              api.setConfig('ha_enabled', v);
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
              onChanged: (v) {
                setState(() => _sensitivity = v);
                api.setConfig('sensitivity', v);
              },
            ),
          ),
          SwitchListTile(
            title: Text(l.t('settings.recording')),
            subtitle: Text(l.t('settings.recording_desc')),
            value: _recordingEnabled,
            onChanged: (v) {
              setState(() => _recordingEnabled = v);
              api.setConfig('recording_enabled', v);
            },
          ),
          const Divider(),
          _buildSection(l.t('settings.about')),
          ListTile(
            title: const Text('Aetheris'),
            subtitle: Text('${l.t('settings.version')} ${AppConstants.version}'),
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
