import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:caregap_app/app/app.dart';
import 'package:caregap_app/app/app_controller.dart';
import 'package:caregap_app/core/api/api_client.dart';
import 'package:caregap_app/core/data/live_care_repository.dart';
import 'package:caregap_app/features/live/presentation/live_analysis_page.dart';
import 'package:caregap_app/features/live/presentation/live_auth_page.dart';
import 'package:caregap_app/features/live/presentation/live_media_page.dart';
import 'package:caregap_app/features/live/presentation/live_record_page.dart';
import 'package:caregap_app/features/live/presentation/live_shell_page.dart';

const past = {
  'person_id': 'person',
  'consultation_id': 'past',
  'record_version_id': 'pv',
  'text': '어제 식사는 두 번 했습니다.',
};
const current = {
  'person_id': 'person',
  'consultation_id': 'current',
  'record_version_id': 'cv',
  'text': '오늘 식사는 세 번 했습니다.',
};
Json analysis(String status) => {
  'id': 'analysis',
  'status': status,
  'review_state': 'draft',
  'version': 1,
  'provider_kind': 'llm',
  'provider_metadata': {'model': 'qwen2.5vl:7b'},
  'error_code': 'INVALID_ANALYSIS',
  'input': {
    'person_id': 'person',
    'past': [
      {'consultation_id': 'past', 'record_version_id': 'pv'},
    ],
    'current': {'consultation_id': 'current', 'record_version_id': 'cv'},
  },
  'sources': [past, current],
  'original': {
    'status': 'draft',
    'findings': [
      {
        'text': '식사 횟수가 늘었습니다.',
        'change': 'improved',
        'evidence': [
          {
            'consultation_id': 'past',
            'record_version_id': 'pv',
            'quote': past['text'],
          },
          {
            'consultation_id': 'current',
            'record_version_id': 'cv',
            'quote': current['text'],
          },
        ],
      },
    ],
    'questions': ['식사 상태는 어떤가요?'],
  },
  'edited': {
    'status': 'draft',
    'findings': [
      {
        'text': '식사 횟수가 늘었습니다.',
        'change': 'improved',
        'evidence': [
          {
            'consultation_id': 'past',
            'record_version_id': 'pv',
            'quote': past['text'],
          },
          {
            'consultation_id': 'current',
            'record_version_id': 'cv',
            'quote': current['text'],
          },
        ],
      },
    ],
    'questions': ['식사 상태는 어떤가요?'],
  },
};
LiveCareRepository repository() {
  final client = ApiClient(
    'https://example.test',
    transport: MockClient((req) async {
      dynamic d;
      switch (req.url.path) {
        case '/api/auth/login':
          d = {
            'access_token': 'fixture-token',
            'expires_in': 3600,
            'actor': {'user_id': 'staff', 'role': 'staff'},
          };
        case '/api/auth/me':
          d = {'user_id': 'staff', 'role': 'staff'};
        case '/api/persons':
          d = [
            {'person_id': 'person', 'synthetic_only': true},
          ];
        case '/api/records':
          d = [past, current];
        case '/api/appointments':
          d = [];
        case '/api/follow-ups':
          d = [
            {
              'follow_up_id': 'task',
              'person_id': 'person',
              'title': '합성 후속 확인',
              'status': 'open',
            },
          ];
        case '/api/notifications':
          d = [
            {
              'notification_id': 'notice',
              'title': '합성 알림',
              'body': '수동 인앱 알림',
              'kind': 'manual',
            },
          ];
        default:
          return http.Response(
            jsonEncode({
              'error': {'code': 'NOT_FOUND'},
            }),
            404,
          );
      }
      return http.Response(
        jsonEncode({'data': d}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
  return LiveCareRepository(client);
}

void main() {
  testWidgets('실제 연동 화면과 5개 탭은 360px·글씨 2배에서도 표시된다', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = repository();
    final app = AppController(repo);
    addTearDown(app.dispose);
    addTearDown(repo.api.close);
    await tester.runAsync(() => app.signIn('synthetic', 'synthetic-password'));
    await tester.pumpWidget(CaregapApp(controller: app));
    await tester.pumpAndSettle();
    expect(find.byType(LiveShellPage), findsOneWidget);
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
    final navigator = Navigator.of(tester.element(find.byType(NavigationBar)));
    for (final page in <Widget>[
      const LiveAuthPage(),
      const LiveAuthPage(register: true),
      const LiveRecordPage(personId: 'person'),
      const LiveRecordPage(personId: 'person', record: current),
      const LiveMediaPage(personId: 'person', source: 'ocr'),
      const LiveMediaPage(personId: 'person', source: 'stt'),
      LiveAnalysisPage(personId: 'person', current: current),
      LiveAnalysisPage(personId: 'person', analysis: analysis('succeeded')),
      const LiveTasksPage(),
      const LiveNoticesPage(),
    ]) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => page));
      await tester.pumpAndSettle();
      if (page is LiveMediaPage && page.source == 'ocr') {
        expect(find.text('카메라로 촬영'), findsOneWidget);
        expect(find.text('실제 인식 요청'), findsNothing);
      }
      expect(
        tester.takeException(),
        isNull,
        reason: page.runtimeType.toString(),
      );
      navigator.pop();
      await tester.pumpAndSettle();
    }
  });
  testWidgets('실패 분석은 검토 제출과 승인 버튼을 제공하지 않는다', (tester) async {
    final repo = repository();
    final app = AppController(repo);
    addTearDown(app.dispose);
    addTearDown(repo.api.close);
    await tester.runAsync(() => app.signIn('synthetic', 'synthetic-password'));
    await tester.pumpWidget(CaregapApp(controller: app));
    await tester.pumpAndSettle();
    final navigator = Navigator.of(tester.element(find.byType(NavigationBar)));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LiveAnalysisPage(personId: 'person', analysis: analysis('failed')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('INVALID_ANALYSIS'), findsOneWidget);
    expect(find.text('검토 제출'), findsNothing);
    expect(find.text('담당자 최종 승인'), findsNothing);
  });
}
