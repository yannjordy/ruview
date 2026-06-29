import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_types.dart';
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
  String? _error;

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
      _error = null;
    });

    _simulateProgress();

    final api = context.read<ApiService>();
    final result = await api.startCalibration(_roomId);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _running = false;
        _phase = 'complete';
        _progress = 100;
      });
    } else {
      setState(() {
        _running = false;
        _phase = 'error';
        _error = result.message ?? 'Erreur de calibration';
      });
    }
  }

  void _simulateProgress() {
    if (!_running) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || !_running) return;
      setState(() {
        _progress = (_progress + 5).clamp(0, 95);
        if (_progress < 40) {
          _phase = 'baseline';
        } else if (_progress < 70) {
          _phase = 'enroll';
        } else {
          _phase = 'optimize';
        }
      });
      if (_progress < 95) _simulateProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${l.t('sensor.calibrate')} — $_roomId')),
      body: Center(
        child: SingleChildScrollView(
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
              const SizedBox(height: 8),
              Text(
                _phaseDescription(l),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _phase == 'error'
                        ? const Color(0xFFEF5350)
                        : _progress == 100
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFF00BCD4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _running ? '$_progress%' : '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF5350), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Color(0xFFEF5350), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (!_running)
                ElevatedButton.icon(
                  onPressed: _startCalibration,
                  icon: Icon(
                    _phase == 'error' ? Icons.refresh : Icons.tune,
                  ),
                  label: Text(
                    _phase == 'complete'
                        ? l.t('calibration.recallbrate')
                        : _phase == 'error'
                            ? 'Réessayer'
                            : l.t('sensor.calibrate'),
                  ),
                ),
              if (_phase == 'complete')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour à la pièce'),
                  ),
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
        'enroll' => Icons.swap_vert,
        'optimize' => Icons.tune,
        'complete' => Icons.check_circle,
        _ => Icons.error,
      },
      size: 80,
      color: switch (_phase) {
        'ready' => const Color(0xFF00BCD4),
        'baseline' => const Color(0xFFFFCA28),
        'enroll' => const Color(0xFFFF9800),
        'optimize' => const Color(0xFF7E57C2),
        'complete' => const Color(0xFF66BB6A),
        _ => const Color(0xFFEF5350),
      },
    );
  }

  String _phaseText(AppLocalizations l) {
    return switch (_phase) {
      'ready' => l.t('calibration.ready'),
      'baseline' => 'Calibration d\'ambiance…',
      'enroll' => 'Enregistrement des profils…',
      'optimize' => 'Optimisation des paramètres…',
      'complete' => l.t('calibration.complete'),
      _ => l.t('calibration.error'),
    };
  }

  String _phaseDescription(AppLocalizations l) {
    return switch (_phase) {
      'ready' => l.t('calibration.ready_desc'),
      'baseline' => 'Mesure du bruit de fond radio. Restez immobile.',
      'enroll' => 'Analyse des signatures CSI. Déplacez-vous dans la pièce.',
      'optimize' => 'Réglage fin des seuils de détection.',
      'complete' => l.t('calibration.complete_desc'),
      _ => l.t('calibration.error'),
    };
  }
}
