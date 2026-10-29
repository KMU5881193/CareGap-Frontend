import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:caregap_app/core/api/api_client.dart';
import 'package:caregap_app/core/api/media_validation.dart';
import 'package:caregap_app/core/data/live_care_repository.dart';
import 'package:caregap_app/core/models/frontend_models.dart';
import 'package:caregap_app/core/models/user_role.dart';
import 'package:caregap_app/core/errors/app_exception.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    throw ArgumentError(
      'Provide current HTTPS BACKEND_URL and optional synthetic WAV path',
    );
  }
  final url = args[0];
  final elapsed = Stopwatch()..start();
  final report = <String, Object?>{
    'base': url,
    'checks': <String>[],
    'completed': false,
  };
  final checks = report['checks'] as List<String>;
  final r = LiveCareRepository(ApiClient(url));
  void check(bool condition, String label) {
    if (!condition) throw StateError(label);
    checks.add(label);
    stdout.writeln('PASS $label');
  }

  try {
    final h = await r.health();
    check(
      h['status'] == 'ok' && h['synthetic_only'] == true,
      'health · 합성 전용 서버',
    );
    final identifier = 'flutter-${requestKey()}', password = requestKey();
    await r.register('', identifier, password, UserRole.staff);
    check((await r.me()).role == UserRole.staff, '회원가입 → 로그인 → me');
    final id = await r.createPerson();
    await r.linkedPeople();
    check(r.persons.any((p) => p['person_id'] == id), '대상자 생성 · 목록');
    final ap = await r.book(
      id,
      DateTime.now().add(const Duration(days: 7)),
      DateTime.now().add(const Duration(days: 7, hours: 1)),
    );
    check(ap['status'] == 'scheduled', '예약 생성');
    await r.bookingAction(ap, 'complete');
    checks.add('예약 완료');
    final past = await r.writeRecord(
      id,
      '어제 식사는 두 번 했습니다. 약을 빠뜨렸습니다. 산책은 한 번 했습니다.',
    );
    final revised = await r.writeRecord(id, past['text'], previous: past);
    check(revised['record_version_id'] != past['record_version_id'], '새 기록 버전');
    try {
      await r.writeRecord(id, '합성 충돌 검사', previous: past);
      throw StateError('버전 충돌 누락');
    } on AppException catch (e) {
      check(e.code == '409', '오래된 기록 버전 409 차단');
    }
    Json current;
    if (args.length > 1) {
      final f = File(args[1]);
      final input = MediaInput(
        name: 'synthetic.wav',
        bytes: await f.readAsBytes(),
        kind: 'audio',
      );
      validateUpload('stt', input);
      var job = await r.createJob('stt', id, input, requestKey());
      check(
        ['pending', 'processing', 'succeeded'].contains(job['status']),
        'STT 작업 생성',
      );
      try {
        await r.importJob('stt', job);
        throw StateError('미확정 가져오기 허용');
      } on AppException catch (e) {
        check(e.code == '409', '미확정 STT 가져오기 차단');
      }
      for (
        int i = 0;
        i < 65 && ['pending', 'processing'].contains(job['status']);
        i++
      ) {
        await Future<void>.delayed(const Duration(seconds: 2));
        job = await r.getJob('stt', job['id']);
      }
      check(job['status'] == 'succeeded', '실제 STT 인식 성공');
      report['stt_provider'] = job['provider_kind'];
      final segments = objects(object(job['original'])['segments']);
      // This is an automated contract test, not a human review or real consultation.
      job = await r.correctJob(
        'stt',
        job,
        '',
        segments: [
          {
            'start_ms': segments.first['start_ms'],
            'end_ms': segments.last['end_ms'],
            'speaker_id': 'unknown',
            'text': '오늘 식사는 세 번 했습니다. 약을 빠뜨리지 않았습니다. 산책은 두 번 했습니다.',
          },
        ],
      );
      job = await r.confirmJob('stt', job);
      current = await r.importJob('stt', job);
      checks.add('STT 교정 → 확정 → 기록 가져오기');
    } else {
      current = await r.writeRecord(
        id,
        '오늘 식사는 세 번 했습니다. 약을 빠뜨리지 않았습니다. 산책은 두 번 했습니다.',
      );
    }
    var analysis = await r.analyze(id, revised, current);
    for (int i = 0; i < 75 && analysis['status'] == 'running'; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      analysis = await r.getAnalysis(analysis['id']);
    }
    check(analysis['status'] == 'succeeded', '실제 상담 비교 분석 성공');
    check(analysis['provider_kind'] == 'llm', 'LLM 제공자 확인');
    report['provider'] = analysis['provider_metadata'];
    report['inference'] = analysis['inference'];
    check(
      analysis['provider_metadata']?['provider'] == 'ollama' &&
          analysis['inference']?['model'] == 'qwen2.5vl:7b' &&
          (analysis['inference']?['eval_count'] as num? ?? 0) > 0,
      '실제 Qwen 추론 메타데이터',
    );
    final findings = objects(object(analysis['edited'])['findings']);
    check(
      findings.length == 3 && findings.every((f) => f['change'] == 'improved'),
      '독립 합성 정답: 식사·복약·산책 개선',
    );
    for (final finding in findings) {
      for (final evidence in objects(finding['evidence'])) {
        final source = [revised, current].where(
          (r) =>
              r['consultation_id'] == evidence['consultation_id'] &&
              r['record_version_id'] == evidence['record_version_id'],
        );
        check(
          source.length == 1 &&
              (evidence['quote'] as String).isNotEmpty &&
              (source.single['text'] as String).contains(
                evidence['quote'] as String,
              ),
          '근거 ID·버전·정확한 원문 일치',
        );
      }
    }
    check(
      findings.isNotEmpty && objects(findings.first['evidence']).length >= 2,
      '이전·현재 근거 반환',
    );
    try {
      await r.recommend(analysis, [
        {
          'need': 'meal_support',
          'finding_index': 0,
          'evidence_index': 0,
          'confirmed': true,
        },
      ]);
      throw StateError('미승인 추천 허용');
    } on AppException catch (e) {
      check(e.code == '409', '미승인 복지 추천 차단');
    }
    analysis = await r.review(analysis, 'submit');
    check(analysis['review_state'] == 'review', '검토 제출');
    analysis = await r.review(analysis, 'approve');
    check(analysis['review_state'] == 'approved', '검토 승인');
    final welfare = await r.recommend(analysis, [
      {
        'need': 'meal_support',
        'finding_index': 0,
        'evidence_index': 0,
        'confirmed': true,
      },
    ]);
    check(
      objects(welfare['candidates']).isNotEmpty &&
          objects(welfare['candidates']).every(
            (c) =>
                c['eligibility_status'] == 'unverified' &&
                c['data_status'] == 'synthetic_demo',
          ),
      '복지 후보 · 합성/자격 미확인',
    );
    await r.addFollowup(id, '합성 식사 상태 재확인');
    await r.createNotice('합성 Flutter 연동 검사', '수동 인앱 알림입니다.');
    await r.load(null);
    check(
      r.tasks.isNotEmpty &&
          r.notices.isNotEmpty &&
          r.recordVersions.length >= 3,
      '기록 이력 · 후속 업무 · 알림 목록',
    );
    await r.taskAction(r.tasks.first, 'complete');
    await r.markRead(r.notices.first['notification_id']);
    await r.load(null);
    check(
      r.tasks.first['status'] == 'completed' &&
          r.notices.first['read_at'] != null,
      '후속 업무 완료 · 알림 읽음',
    );
    await r.logout();
    check(r.api.token == null, '로그아웃 · 로컬 토큰 제거');
    report['completed'] = true;
  } catch (e) {
    report['error'] = e is AppException
        ? e.toString()
        : '검증 실패: ${e.runtimeType}';
    stderr.writeln(report['error']);
    exitCode = 1;
  } finally {
    r.api.close();
    report['checked_at'] = DateTime.now().toUtc().toIso8601String();
    report['elapsed_ms'] = elapsed.elapsedMilliseconds;
    final f = File('${Directory.systemTemp.path}/caregap_live_api_report.json');
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    stdout.writeln('Report: ${f.path}');
  }
}
