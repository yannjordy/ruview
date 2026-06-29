import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../core/constants.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  late String _roomId;
  int _progress = 0;
  String _phase = 'ready';
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _roomId = ModalRoute.of(context)!.settings.arguments as String;
  }

  Future<void> _startCalibration() async {
    setState(() {
      _running = true;
      _phase = 'baseline';
      _progress = 0;
    });

    final api = context.read<ApiService>();
    final result = await api.startCalibration(_roomId);

    if (mounted) {
      setState(() {
        _running = false;
        _phase = result.completed ? 'complete' : 'error';
        _progress = result.completed ? 100 : _progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${l.t('sensor.calibrate')} — $_roomId')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPhaseIcon(),
              const SizedBox(height: 32),
              Text(
                _phaseText(l),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _phase == 'baseline'
                    ? l.t('calibration.stay_still')
                    : _phase == 'ready'
                        ? l.t('calibration.ready_desc')
                        : _phase == 'complete'
                            ? l.t('calibration.complete_desc')
                            : '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _progress == 100
                        ? const Color(0xFF66BB6A)
                        : const Color(0xFF00BCD4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('${_progress}%',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 32),
              if (!_running)
                ElevatedButton.icon(
                  onPressed: _startCalibration,
                  icon: const Icon(Icons.tune),
                  label: Text(_phase == 'complete'
                      ? l.t('calibration.recallbrate')
                      : l.t('sensor.calibrate')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseIcon() {
    return Icon(
      switch (_phase) {
        'ready' => Icons.sensors,
        'baseline' => Icons.running_with_errors,
        'complete' => Icons.check_circle,
        _ => Icons.error,
      },
      size: 80,
      color: switch (_phase) {
        'ready' => const Color(0xFF00BCD4),
        'baseline' => const Color(0xFFFFCA28),
        'complete' => const Color(0xFF66BB6A),
        _ => const Color(0xFFEF5350),
      },
    );
  }

  String _phaseText(AppLocalizations l) {
    return switch (_phase) {
      'ready' => l.t('calibration.ready'),
      'baseline' => l.t('calibration.in_progress'),
      'complete' => l.t('calibration.complete'),
      _ => l.t('calibration.error'),
    };
  }
}
