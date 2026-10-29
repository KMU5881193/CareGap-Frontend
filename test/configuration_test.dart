import 'package:flutter_test/flutter_test.dart';
import 'package:caregap_app/main.dart' as entry;
import 'package:caregap_app/core/config/app_config.dart';

void main() {
  testWidgets(
    'missing live URL shows configuration guidance without mock fallback',
    (tester) async {
      if (AppConfig.useMock || AppConfig.backendConfigured) return;
      await entry.main();
      await tester.pump();
      expect(find.textContaining('실제 API 주소 설정이 필요합니다.'), findsOneWidget);
      expect(find.textContaining('BACKEND_URL'), findsOneWidget);
    },
  );
}
