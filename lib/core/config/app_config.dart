abstract final class AppConfig {
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue:
        'https://favourite-bizrate-passed-calibration.trycloudflare.com',
  );
}
