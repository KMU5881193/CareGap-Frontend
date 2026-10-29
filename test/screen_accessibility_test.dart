import 'package:caregap_app/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:caregap_app/app/app.dart';
import 'package:caregap_app/app/app_controller.dart';
import 'package:caregap_app/core/data/mock_care_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caregap_app/features/appointments/presentation/pages/appointment_detail_page.dart';
import 'package:caregap_app/features/appointments/presentation/pages/availability_page.dart';
import 'package:caregap_app/features/records/presentation/pages/record_detail_page.dart';
import 'package:caregap_app/features/records/presentation/pages/record_editor_page.dart';
import 'package:caregap_app/features/records/presentation/pages/record_import_page.dart';
import 'package:caregap_app/features/records/presentation/pages/record_handover_page.dart';
import 'package:caregap_app/features/analysis/presentation/pages/analysis_detail_page.dart';
import 'package:caregap_app/features/analysis/presentation/pages/analysis_review_page.dart';
import 'package:caregap_app/features/analysis/presentation/pages/cumulative_analysis_page.dart';
import 'package:caregap_app/features/beneficiaries/presentation/pages/beneficiary_detail_page.dart';
import 'package:caregap_app/features/connections/presentation/pages/connections_page.dart';
import 'package:caregap_app/features/settings/presentation/pages/accessibility_page.dart';
import 'package:caregap_app/features/settings/presentation/pages/profile_page.dart';
import 'package:caregap_app/features/settings/presentation/pages/help_page.dart';
import 'package:caregap_app/features/settings/presentation/pages/password_change_page.dart';
import 'package:caregap_app/features/settings/presentation/pages/account_withdrawal_page.dart';
import 'package:caregap_app/features/counseling/presentation/pages/counseling_entry_page.dart';
import 'package:caregap_app/features/welfare/presentation/pages/welfare_detail_page.dart';

void main() {
  testWidgets('상세·설정·미디어 화면은 360px와 두 배 글씨에서 오류 없이 표시된다', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = AppController(MockCareRepository());
    addTearDown(app.dispose);
    await tester.runAsync(() => app.signIn('staff', 'care1234'));
    await tester.pumpWidget(CaregapApp(controller: app));
    await tester.pumpAndSettle();
    final navigator = Navigator.of(tester.element(find.byType(NavigationBar)));
    for (final page in <Widget>[
      const AppointmentDetailPage(appointmentId: "a1"),
      const AvailabilityPage(),
      const RecordDetailPage(recordId: "r1"),
      const RecordEditorPage(targetId: "p1"),
      const RecordImportPage(),
      const RecordHandoverPage(recordId: "r1"),
      const AnalysisDetailPage(recordId: "r1"),
      const AnalysisReviewPage(recordId: "r1"),
      const CumulativeAnalysisPage(),
      const BeneficiaryDetailPage(targetId: "p1"),
      const ConnectionsPage(),
      const AccessibilityPage(),
      const NotificationSettingsPage(),
      const ProfilePage(),
      const HelpPage(),
      const PasswordChangePage(),
      const AccountWithdrawalPage(),
      const CallPreviewPage(),
      const WelfareDetailPage(serviceId: "w1"),
      const ChatPreviewPage(),
    ]) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => page));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
      navigator.pop();
      await tester.pumpAndSettle();
    }
  });
}
