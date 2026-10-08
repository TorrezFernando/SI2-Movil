class ApiConstants {
  const ApiConstants._();

  static const String androidEmulator = 'http://192.168.100.4:8000';
  static const String iosSimulator = 'http://192.168.100.4:8000';
  static const String physicalDevice = 'http://192.168.100.4:8000';
  static const String webLocalhost = 'http://localhost:8000';

  // Override with: flutter run --dart-define=API_BASE_URL=http://...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: physicalDevice,
  );
}
