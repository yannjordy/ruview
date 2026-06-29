import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/room_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/calibration_screen.dart';

class AetherisApp extends StatelessWidget {
  const AetherisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aetheris',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
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
        '/settings': (ctx) => const SettingsScreen(),
        '/calibrate': (ctx) => const CalibrationScreen(),
      },
    );
  }
}
