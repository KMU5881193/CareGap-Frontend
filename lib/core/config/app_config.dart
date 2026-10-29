abstract final class AppConfig {
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
}
