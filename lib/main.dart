import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/media/media_service.dart';
import 'core/notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Pretendard',
    ], await rootBundle.loadString('assets/fonts/PRETENDARD_LICENSE.txt'));
  });
  await MediaSelectionService.instance.recoverLostData();
  await PushService.instance.initialize();
  runApp(const CaregapApp());
}
