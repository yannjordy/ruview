class AppConstants {
  AppConstants._();

  static const appName = 'Aetheris';
  static const version = '1.0.0';

  static const apiBaseUrl = 'http://localhost:3000/api/v1';
  static const wsUrl = 'ws://localhost:3000/ws';
  static const mqttBroker = 'localhost';
  static const mqttPort = 1883;

  static const sensorPollInterval = Duration(milliseconds: 200);
  static const reconnectionDelay = Duration(seconds: 5);
  static const calibrationDuration = Duration(seconds: 30);
}
