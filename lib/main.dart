import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/media/media_service.dart';
import 'core/notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.useMock && !AppConfig.backendConfigured) {
    runApp(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SelectableText(
                  '실제 API 주소 설정이 필요합니다.\n'
                  '최신 HTTPS 서버 주소를 --dart-define=BACKEND_URL=...로 지정한 뒤 다시 실행해 주세요.\n'
                  '화면 체험만 하려면 --dart-define=USE_MOCK=true를 명시하세요.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Pretendard',
    ], await rootBundle.loadString('assets/fonts/PRETENDARD_LICENSE.txt'));
  });
  await MediaSelectionService.instance.recoverLostData();
  await PushService.instance.initialize();
  runApp(const CaregapApp());
}
