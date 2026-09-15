class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const bool useMockApi = false;

  static const String appName = 'UMIS Core';
  static const String appTagline = 'Umoja wa Vijana wa CCM';
  static const String appMotto = 'UMOJA • NGUVU • MAENDELEO';

  static const Duration requestTimeout = Duration(seconds: 30);
}
