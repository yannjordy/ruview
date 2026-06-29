import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/room_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/calibration_screen.dart';

class AetherisApp extends StatefulWidget {
  const AetherisApp({super.key});

  @override
  State<AetherisApp> createState() => _AetherisAppState();
}

class _AetherisAppState extends State<AetherisApp> {
  final ApiService _apiService = ApiService();
  late Locale _locale;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initLocale();
  }

  Future<void> _initLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'fr';
    setState(() {
      _locale = Locale(lang);
      _ready = true;
    });
  }

  void _changeLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _apiService,
      child: MaterialApp(
        title: 'Aetheris',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
        ],
        initialRoute: '/',
        routes: {
          '/': (ctx) => const DashboardScreen(),
          '/room': (ctx) => const RoomDetailScreen(),
          '/settings': (ctx) => SettingsScreen(
                onLocaleChanged: _changeLocale,
              ),
          '/calibrate': (ctx) => const CalibrationScreen(),
        },
      ),
    );
  }
}
