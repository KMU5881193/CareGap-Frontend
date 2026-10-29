abstract final class AppConfig {
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
  static bool get backendConfigured {
    final uri = Uri.tryParse(backendUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        (uri.path.isEmpty || uri.path == '/');
  }
}
