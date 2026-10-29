import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caregap_app/app/app.dart';
import 'package:caregap_app/app/app_controller.dart';
import 'package:caregap_app/core/api/api_client.dart';
import 'package:caregap_app/core/data/live_care_repository.dart';
import 'package:caregap_app/features/live/presentation/live_patient_page.dart';
import 'package:caregap_app/features/live/presentation/live_shell_page.dart';

void main() {
  testWidgets('four actual local server accounts render staff or patient UI', (
    tester,
  ) async {
    HttpOverrides.global = null;
    final accounts = jsonDecode(
      (await tester.runAsync(
        () => File(
          '../final-verification-CareGap-Backend/.runtime/demo-credentials.json',
        ).readAsString(),
      ))!,
    ) as List;
    for (int i = 0; i < 4; i++) {
      final repo = LiveCareRepository(ApiClient('http://127.0.0.1:4334'));
      final app = AppController(repo);
      await tester.runAsync(
        () => app.signIn(accounts[i]['identifier'], accounts[i]['password']),
      );
      expect(app.error, isNull);
      expect(app.workspaceReady, true);
      await tester.pumpWidget(CaregapApp(key: ValueKey(i), controller: app));
      await tester.pumpAndSettle();
      if (i < 2) {
        expect(find.byType(LiveShellPage), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
      } else {
        expect(find.byType(LivePatientPage), findsOneWidget);
        expect(find.text('내 예약과 상담 기록'), findsOneWidget);
        expect(find.text('상담 예약'), findsOneWidget);
        expect(find.text('상담 기록 작성 · OCR/STT'), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(app.signOut);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
      repo.api.close();
    }
  });
}
