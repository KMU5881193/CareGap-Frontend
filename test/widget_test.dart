import 'package:caregap_app/app/app.dart';
import 'package:caregap_app/app/app_controller.dart';
import 'package:caregap_app/core/data/mock_care_repository.dart';
import 'package:caregap_app/core/widgets/app_button.dart';
import 'package:caregap_app/features/appointments/presentation/pages/appointment_request_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void smallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets('큰 글씨에서 시작→역할 선택→체험 가입 화면을 스크롤할 수 있다', (tester) async {
    smallScreen(tester);
    await tester.pumpWidget(const CaregapApp());
    await tester.ensureVisible(find.text('시작하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('대상자'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대상자'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('체험 계정 만들기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final account in ['beneficiary', 'staff']) {
    testWidgets('$account 계정의 5개 탭과 상담 신청은 큰 글씨에서도 넘치지 않는다', (tester) async {
      smallScreen(tester);
      final app = AppController(MockCareRepository());
      addTearDown(app.dispose);
      await tester.runAsync(() => app.signIn(account, 'care1234'));
      await tester.pumpWidget(CaregapApp(controller: app));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final label in ['일정', '기록', '복지정보', '더보기', '홈']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
      }
      final context = tester.element(find.byType(NavigationBar));
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AppointmentRequestPage()),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('신청 내용 확인'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('체험 로그인 후 인증된 대상자 홈으로 이동한다', (tester) async {
    await tester.pumpWidget(const CaregapApp());
    await tester.ensureVisible(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ActionChip, '대상자'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, '대상자'));
    await tester.ensureVisible(find.widgetWithText(AppButton, '로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, '로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('김하늘 님'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('미연결 가족은 홈 메뉴와 대상자 이름에 접근하지 못한다', (tester) async {
    final app = AppController(MockCareRepository());
    addTearDown(app.dispose);
    await tester.runAsync(() => app.signIn('family_pending', 'care1234'));
    await tester.pumpWidget(CaregapApp(controller: app));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('대상자의 연결 허용이 필요해요'), findsOneWidget);
    expect(find.textContaining('김하늘'), findsNothing);
  });
}
