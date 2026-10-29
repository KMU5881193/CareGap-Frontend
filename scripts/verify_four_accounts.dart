import 'dart:convert';
import 'dart:io';

import 'package:caregap_app/core/api/api_client.dart';
import 'package:caregap_app/core/data/live_care_repository.dart';
import 'package:caregap_app/core/models/frontend_models.dart';
import 'package:caregap_app/core/models/user_role.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw ArgumentError('URL and local credential file required');
  }
  final accounts = jsonDecode(await File(args[1]).readAsString()) as List;
  final results = <Map<String, dynamic>>[];
  for (int i = 0; i < 4; i++) {
    final account = accounts[i] as Map;
    final repo = LiveCareRepository(ApiClient(args[0]));
    try {
      final user = await repo.login(account['identifier'], account['password']);
      if (user.role != (i < 2 ? UserRole.staff : UserRole.beneficiary)) {
        throw StateError('Wrong role');
      }
      await repo.linkedPeople();
      await repo.load(null);
      if (repo.persons.length != 1 ||
          repo.appointments.length < 2 ||
          repo.recordVersions.length < 3) {
        throw StateError('Missing demo data');
      }
      results.add({
        'user_id': user.id,
        'role': account['role'],
        'people': repo.persons.length,
        'appointments': repo.appointments.length,
        'record_versions': repo.recordVersions.length,
        'real_http': true,
      });
      if (i == 0) {
        final person = repo.persons.single['person_id'] as String;
        for (final source in ['ocr', 'stt']) {
          final name = source == 'ocr'
              ? 'person-0-synthetic.png'
              : 'person-0.wav';
          final file = MediaInput(
            name: name,
            bytes: await File(
              '../final-verification-CareGap-Backend/.runtime/$name',
            ).readAsBytes(),
            kind: source == 'ocr' ? 'image' : 'audio',
          );
          var job = await repo.createJob(
            source,
            person,
            file,
            'flutter-final-$source',
          );
          for (
            int poll = 0;
            poll < 90 && ['pending', 'processing'].contains(job['status']);
            poll++
          ) {
            await Future<void>.delayed(const Duration(seconds: 1));
            job = await repo.getJob(source, job['id']);
          }
          if (job['status'] != 'succeeded') {
            throw StateError('Actual $source failed');
          }
          if (job['version'] == 0) {
            const text =
                '[합성 데모] 현재 식사는 하루 세 번 했습니다. 약을 빠뜨리지 않았습니다. 산책은 일주일에 두 번 했습니다.';
            final segments = source == 'stt'
                ? objects(object(job['original'])['segments'])
                : <Json>[];
            job = await repo.correctJob(
              source,
              job,
              text,
              segments: source == 'stt'
                  ? [
                      {
                        'start_ms': segments.first['start_ms'],
                        'end_ms': segments.last['end_ms'],
                        'speaker_id': 'unknown',
                        'text': text,
                      },
                    ]
                  : null,
            );
          }
          if (job['confirmed'] == null) {
            job = await repo.confirmJob(source, job);
          }
          await repo.importJob(source, job);
          results.last['${source}_job_id'] = job['id'];
          results.last['${source}_original'] = job['original'];
        }
        await repo.load(null);
        final records = repo.latestRecords(person);
        final past = records.firstWhere(
          (r) => (r['text'] as String).contains('과거에는'),
        );
        final current = records.firstWhere(
          (r) => (r['text'] as String).contains('현재 식사'),
        );
        var analysis = await repo.analyze(person, past, current);
        if (analysis['status'] != 'succeeded' ||
            analysis['provider_metadata']['provider'] != 'ollama' ||
            analysis['inference']['eval_count'] <= 0) {
          throw StateError('Real model failed');
        }
        for (final f in objects(object(analysis['edited'])['findings'])) {
          for (final e in objects(f['evidence'])) {
            final source = records.singleWhere(
              (r) => r['record_version_id'] == e['record_version_id'],
            );
            if (!(source['text'] as String).contains(e['quote'])) {
              throw StateError('Evidence mismatch');
            }
          }
        }
        if (analysis['review_state'] == 'draft') {
          analysis = await repo.review(analysis, 'submit');
        }
        if (analysis['review_state'] == 'review') {
          analysis = await repo.review(analysis, 'approve');
        }
        final welfare = await repo.recommend(analysis, [
          {
            'need': 'meal_support',
            'finding_index': 0,
            'evidence_index': 0,
            'confirmed': true,
          },
        ]);
        results.last['analysis_id'] = analysis['id'];
        results.last['inference'] = analysis['inference'];
        results.last['candidates'] = objects(welfare['candidates']).length;
        final path = File(
          '../final-verification-CareGap-Backend/.runtime/vision-synthetic.png',
        );
        final vision = await repo.analyzeImage(
          person,
          MediaInput(
            name: 'vision-synthetic.png',
            bytes: await path.readAsBytes(),
            kind: 'image',
          ),
          requestKey(),
        );
        if (vision['provenance']['ocr_used'] != false) {
          throw StateError('Wrong vision provenance');
        }
        results.last['vision_status'] = vision['status'];
      }
      await repo.logout();
    } finally {
      repo.api.close();
    }
  }
  await Directory('.runtime').create(recursive: true);
  await File('.runtime/four-accounts-live.json').writeAsString(
    const JsonEncoder.withIndent('  ')
        .convert({'base': args[0], 'use_mock': false, 'results': results}),
  );
  stdout.writeln(
    'PASS real HTTP: 4 logins, assigned data, Qwen/evidence/review/welfare, direct Vision',
  );
}
