abstract final class AppConfig {
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const configuredBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
  // Public demo bundles call the origin from which they were actually loaded.
  // This prevents a remote phone from calling its own localhost.
  static String get backendUrl =>
      const bool.fromEnvironment('USE_SAME_ORIGIN', defaultValue: false)
      ? Uri.base.origin
      : configuredBackendUrl;
  static bool get backendConfigured {
    final uri = Uri.tryParse(backendUrl);
    return uri != null &&
        (uri.scheme == 'https' ||
            (const bool.fromEnvironment(
                  'ALLOW_LOOPBACK_HTTP',
                  defaultValue: false,
                ) &&
                uri.scheme == 'http' &&
                ['127.0.0.1', 'localhost', '::1'].contains(uri.host))) &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        (uri.path.isEmpty || uri.path == '/');
  }
}
