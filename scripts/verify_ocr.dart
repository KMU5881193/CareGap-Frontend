import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:caregap_app/core/api/api_client.dart';
import 'package:caregap_app/core/api/media_validation.dart';
import 'package:caregap_app/core/data/live_care_repository.dart';
import 'package:caregap_app/core/models/frontend_models.dart';
import 'package:caregap_app/core/models/user_role.dart';

Future<void> main(List<String> args) async {
  final repo = LiveCareRepository(ApiClient(args[0]));
  final report = <String, Object?>{'source': 'ocr', 'completed': false};
  try {
    await repo.register(
      '',
      'ocr-${requestKey()}',
      requestKey(),
      UserRole.staff,
    );
    final person = await repo.createPerson();
    final input = MediaInput(
      name: 'synthetic.png',
      bytes: await File(args[1]).readAsBytes(),
      kind: 'image',
    );
    validateUpload('ocr', input);
    var job = await repo.createJob('ocr', person, input, requestKey());
    for (
      int i = 0;
      i < 65 && ['pending', 'processing'].contains(job['status']);
      i++
    ) {
      await Future<void>.delayed(const Duration(seconds: 2));
      job = await repo.getJob('ocr', job['id']);
    }
    if (job['status'] != 'succeeded') {
      throw StateError('OCR status ${job['status']}');
    }
    report['provider_kind'] = job['provider_kind'];
    report['recognized_nonempty'] = (job['original'] as String)
        .trim()
        .isNotEmpty;
    job = await repo.correctJob('ocr', job, '오늘 식사는 세 번 했습니다.');
    job = await repo.confirmJob('ocr', job);
    final record = await repo.importJob('ocr', job);
    report['completed'] = record['text'] == '오늘 식사는 세 번 했습니다.';
    await repo.logout();
    stdout.writeln('PASS 실제 OCR → 교정 → 확정 → 기록 가져오기');
  } catch (e) {
    report['error'] = '${e.runtimeType}: $e';
    exitCode = 1;
  } finally {
    repo.api.close();
    await File('/private/tmp/caregap_ocr_report.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  }
}
