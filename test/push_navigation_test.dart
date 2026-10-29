import 'package:caregap_app/app/app.dart';
import 'package:caregap_app/app/app_controller.dart';
import 'package:caregap_app/core/data/mock_care_repository.dart';
import 'package:caregap_app/core/notifications/push_service.dart';
import 'package:caregap_app/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('종료 상태 알림 터치는 로그인과 자료 로드가 끝날 때까지 보류한다', (tester) async {
    final app = AppController(MockCareRepository());
    final push = PushService.instance;
    push.pendingOpen = true;
    addTearDown(push.consumeOpen);
    addTearDown(app.dispose);
    await tester.pumpWidget(CaregapApp(controller: app));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsPage), findsNothing);
    expect(push.pendingOpen, isTrue);
    await tester.runAsync(() => app.signIn('staff', 'care1234'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsPage), findsOneWidget);
    expect(push.pendingOpen, isFalse);
    expect(find.text('Firebase 프로젝트 연결 대기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('알림 터치가 미연결 가족의 접근 제한을 우회하지 않는다', (tester) async {
    final app = AppController(MockCareRepository());
    final push = PushService.instance;
    push.pendingOpen = true;
    addTearDown(push.consumeOpen);
    addTearDown(app.dispose);
    await tester.runAsync(() => app.signIn('family_pending', 'care1234'));
    await tester.pumpWidget(CaregapApp(controller: app));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsPage), findsNothing);
    expect(push.pendingOpen, isTrue);
    expect(find.text('대상자의 연결 허용이 필요해요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
