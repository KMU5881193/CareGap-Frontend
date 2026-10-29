import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:caregap_app/core/api/api_client.dart';
import 'package:caregap_app/core/api/media_validation.dart';
import 'package:caregap_app/core/data/live_care_repository.dart';
import 'package:caregap_app/core/errors/app_exception.dart';
import 'package:caregap_app/core/media/media_service.dart';
import 'package:caregap_app/core/models/frontend_models.dart';

void main() {
  ApiClient client(Future<http.Response> Function(http.Request) handler) =>
      ApiClient('https://example.test', transport: MockClient(handler))
        ..token = 'test-token'
        ..expiresAt = DateTime.now().add(const Duration(hours: 1));
  test('Bearer 토큰은 헤더에만 전달하고 logout 204를 JSON으로 파싱하지 않는다', () async {
    final c = client((req) async {
      expect(req.headers['Authorization'], 'Bearer test-token');
      expect(req.url.query, isEmpty);
      return http.Response('', 204);
    });
    expect(await c.request('POST', '/api/auth/logout', body: {}), isNull);
    c.close();
  });
  test('401은 토큰을 제거하고 409는 세션을 보존한다', () async {
    int status = 409, expired = 0;
    final c = client(
      (_) async => http.Response(
        jsonEncode({
          'error': {'code': 'CONFLICT'},
        }),
        status,
      ),
    );
    c.onUnauthorized = () => expired++;
    await expectLater(
      c.request('GET', '/api/persons'),
      throwsA(isA<AppException>().having((e) => e.code, 'status', '409')),
    );
    expect(c.token, 'test-token');
    status = 401;
    await expectLater(
      c.request('GET', '/api/persons'),
      throwsA(isA<AppException>().having((e) => e.code, 'status', '401')),
    );
    expect(c.token, isNull);
    expect(expired, 1);
    c.close();
  });
  test('만료된 세션은 요청을 전송하지 않는다', () async {
    final c = client((_) async {
      fail('만료 토큰이 전송됨');
    });
    c.expiresAt = DateTime(2000);
    await expectLater(
      c.request('GET', '/api/persons'),
      throwsA(isA<AppException>()),
    );
    expect(c.token, isNull);
    c.close();
  });
  test('터널 HTML 오류는 명시적으로 실패하고 Mock 자료로 대체하지 않는다', () async {
    final c = client(
      (_) async => http.Response('<html>bad gateway</html>', 502),
    );
    await expectLater(
      c.request('GET', '/api/persons'),
      throwsA(isA<AppException>().having((e) => e.code, 'status', '502')),
    );
    c.close();
  });
  test('기록 수정은 서버가 반환한 정확한 버전으로 요청한다', () async {
    final c = client((req) async {
      expect(req.url.path, '/api/records/server-consultation/versions');
      expect(jsonDecode(req.body), {
        'expected_record_version_id': 'server-version',
        'text': '합성 수정',
      });
      return http.Response(
        jsonEncode({
          'data': {
            'consultation_id': 'server-consultation',
            'record_version_id': 'new-version',
            'text': '합성 수정',
          },
        }),
        201,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final r = LiveCareRepository(c);
    final value = await r.writeRecord(
      'person',
      '합성 수정',
      previous: {
        'consultation_id': 'server-consultation',
        'record_version_id': 'server-version',
      },
    );
    expect(value['record_version_id'], 'new-version');
    c.close();
  });
  test('같은 분석 재시도에는 동일한 Idempotency-Key와 실제 기록 ID를 사용한다', () async {
    final keys = <String>[];
    final c = client((req) async {
      keys.add(req.headers['Idempotency-Key']!);
      expect(jsonDecode(req.body)['current'], {
        'consultation_id': 'current',
        'record_version_id': 'cv',
      });
      return http.Response(
        jsonEncode({
          'data': {'id': 'analysis', 'status': 'running'},
        }),
        200,
      );
    });
    final r = LiveCareRepository(c);
    for (int i = 0; i < 2; i++) {
      await r.analyze(
        'person',
        {'consultation_id': 'past', 'record_version_id': 'pv'},
        {'consultation_id': 'current', 'record_version_id': 'cv'},
      );
    }
    expect(keys[0], keys[1]);
    c.close();
  });
  test('HTTP 200의 failed 분석을 성공으로 바꾸지 않는다', () async {
    final c = client(
      (_) async => http.Response(
        jsonEncode({
          'data': {
            'id': 'failed-analysis',
            'status': 'failed',
            'error_code': 'INVALID_ANALYSIS',
          },
        }),
        200,
      ),
    );
    final r = LiveCareRepository(c);
    final a = await r.analyze(
      'person',
      {'consultation_id': 'past', 'record_version_id': 'pv'},
      {'consultation_id': 'current', 'record_version_id': 'cv'},
    );
    expect(a['status'], 'failed');
    expect(a['error_code'], 'INVALID_ANALYSIS');
    c.close();
  });
  test('검토 요청은 최신 버전으로 한 단계만 변경한다', () async {
    final c = client((req) async {
      expect(req.url.path, '/api/analysis-reviews/analysis');
      expect(jsonDecode(req.body), {'action': 'submit', 'expected_version': 7});
      return http.Response(
        jsonEncode({
          'data': {'id': 'analysis', 'version': 8, 'review_state': 'review'},
        }),
        200,
      );
    });
    final r = LiveCareRepository(c);
    final a = await r.review({'id': 'analysis', 'version': 7}, 'submit');
    expect(a['review_state'], 'review');
    c.close();
  });
  test('지원 필요는 선택한 실제 근거 인덱스를 보낸다', () async {
    final c = client((req) async {
      final body = jsonDecode(req.body);
      expect(body['expected_analysis_version'], 9);
      expect(body['confirmations'][0]['finding_index'], 2);
      expect(body['confirmations'][0]['evidence_index'], 1);
      return http.Response(
        jsonEncode({
          'data': {'candidates': []},
        }),
        200,
      );
    });
    final r = LiveCareRepository(c);
    await r.recommend(
      {'id': 'analysis', 'version': 9},
      [
        {
          'need': 'mobility_support',
          'finding_index': 2,
          'evidence_index': 1,
          'confirmed': true,
        },
      ],
    );
    c.close();
  });
  test('이전 토큰 요청의 늦은 401이 새 로그인 토큰을 지우지 않는다', () async {
    final pending = Completer<http.Response>();
    final c = client((_) => pending.future);
    final call = c.request('GET', '/api/persons');
    c.token = 'new-test-token';
    pending.complete(
      http.Response(
        jsonEncode({
          'error': {'code': 'UNAUTHENTICATED'},
        }),
        401,
      ),
    );
    await expectLater(call, throwsA(isA<AppException>()));
    expect(c.token, 'new-test-token');
    c.close();
  });
  test('세션 정리 후 늦은 대상자 응답을 캐시에 저장하지 않는다', () async {
    final pending = Completer<http.Response>();
    final c = client((_) => pending.future),
        r = LiveCareRepository(client((_) => pending.future));
    final call = r.linkedPeople();
    r.clearData();
    pending.complete(
      http.Response(
        jsonEncode({
          'data': [
            {'person_id': 'previous-person'},
          ],
        }),
        200,
      ),
    );
    await expectLater(
      call,
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'CANCELLED')),
    );
    expect(r.persons, isEmpty);
    r.api.close();
    c.close();
  });
  test('WAV 형식은 확장자가 아닌 헤더로 검증한다', () {
    final wav = AudioCapture.makeWav(Uint8List(320));
    validateUpload(
      'stt',
      MediaInput(name: 'synthetic.wav', bytes: wav, kind: 'audio'),
    );
    final bad = Uint8List.fromList(wav);
    ByteData.sublistView(bad).setUint16(22, 2, Endian.little);
    expect(
      () => validateUpload(
        'stt',
        MediaInput(name: 'stereo.wav', bytes: bad, kind: 'audio'),
      ),
      throwsA(isA<AppException>()),
    );
    expect(
      () => validateUpload(
        'ocr',
        MediaInput(name: 'fake.png', bytes: Uint8List(32), kind: 'image'),
      ),
      throwsA(isA<AppException>()),
    );
  });
}
