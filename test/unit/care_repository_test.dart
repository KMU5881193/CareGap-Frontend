import 'package:caregap_app/app/app_controller.dart';
import 'package:caregap_app/core/data/mock_care_repository.dart';
import 'package:caregap_app/core/errors/app_exception.dart';
import 'package:caregap_app/core/models/care_models.dart';
import 'package:caregap_app/core/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Matcher denied() =>
      throwsA(isA<AppException>().having((e) => e.code, 'code', '403'));

  test('대상자는 자신의 공개 요약·승인 결과만 받고 내부 메모는 받지 않는다', () async {
    final repo = MockCareRepository();
    await repo.login('beneficiary', 'care1234');
    final data = await repo.load('p1');
    expect(data.records.length, 2);
    expect(
      data.records.every(
        (r) =>
            r.targetId == 'p1' && r.original.isEmpty && r.internalNote.isEmpty,
      ),
      isTrue,
    );
    expect(data.records.every((r) => r.analysis?.approved == true), isTrue);
    await expectLater(repo.load('p2'), denied());
    await expectLater(
      repo.saveRecord(targetId: 'p1', original: '무단 수정', note: ''),
      denied(),
    );
  });

  test('미연결 가족과 미승인 담당자는 업무 데이터를 조회할 수 없다', () async {
    final repo = MockCareRepository();
    await repo.login('family_pending', 'care1234');
    await expectLater(repo.load('p1'), denied());
    await repo.login('staff_pending', 'care1234');
    await expectLater(repo.load(null), denied());
    await repo.login('staff_rejected', 'care1234');
    await expectLater(repo.load(null), denied());
  });

  test('가족 허용 후 접근 가능하고 연결 해제 후에는 접근이 차단된다', () async {
    final repo = MockCareRepository();
    await repo.login('beneficiary', 'care1234');
    await repo.familyAction('family_pending', 'p1', true);
    await repo.login('family_pending', 'care1234');
    expect((await repo.load('p1')).records, isNotEmpty);
    await repo.login('beneficiary', 'care1234');
    await repo.familyAction('family_pending', 'p1', false);
    await repo.login('family_pending', 'care1234');
    await expectLater(repo.load('p1'), denied());
  });

  test('체험 가족 연결 요청은 허용 전까지 권한을 부여하지 않는다', () async {
    final repo = MockCareRepository();
    await repo.register('새 가족', 'new_family', 'password1', UserRole.family);
    await repo.requestFamilyLink('DEMO123');
    expect((await repo.me()).targetIds, isEmpty);
    await expectLater(repo.load('p1'), denied());
  });

  test('상담 중복을 막고 요청자는 자신의 요청을 수락할 수 없다', () async {
    final repo = MockCareRepository();
    await repo.login('beneficiary', 'care1234');
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day + 8, 14);
    final appointment = await repo.requestAppointment(
      targetId: 'p1',
      start: start,
      type: VisitType.visit,
      reason: '예시 상담',
      place: '체험 센터',
    );
    await expectLater(
      repo.requestAppointment(
        targetId: 'p1',
        start: start.add(const Duration(minutes: 30)),
        type: VisitType.phone,
        reason: '중복 요청',
        place: '',
      ),
      throwsA(isA<AppException>().having((e) => e.code, 'code', '409')),
    );
    await expectLater(
      repo.appointmentAction(appointment.id, 'accept'),
      denied(),
    );
    await repo.login('staff', 'care1234');
    await repo.appointmentAction(appointment.id, 'accept');
    expect(
      (await repo.load(null)).appointments
          .firstWhere((a) => a.id == appointment.id)
          .status,
      AppointmentStatus.confirmed,
    );
    final newTime = start.add(const Duration(days: 1));
    await repo.appointmentAction(appointment.id, 'change', start: newTime);
    var changed = (await repo.load(null)).appointments
        .firstWhere((a) => a.id == appointment.id);
    expect(changed.start, start);
    expect(changed.proposedStart, newTime);
    await repo.login('beneficiary', 'care1234');
    await repo.appointmentAction(appointment.id, 'accept');
    changed = (await repo.load('p1')).appointments
        .firstWhere((a) => a.id == appointment.id);
    expect(changed.start, newTime);
    expect(changed.proposedStart, isNull);
  });

  test('기록 수정은 기존 분석 승인을 무효화하고 새 검토 승인은 자동 공개하지 않는다', () async {
    final repo = MockCareRepository();
    await repo.login('staff', 'care1234');
    final record = await repo.saveRecord(
      id: 'r1',
      targetId: 'p1',
      original: '수정한 합성 상담 원문',
      note: '내부 메모',
    );
    expect(record.analysis, isNull);
    expect(record.published, isFalse);
    await repo.requestAnalysis(record.id);
    await repo.approveAnalysis(record.id, '검토한 합성 요약');
    await repo.login('beneficiary', 'care1234');
    expect(
      (await repo.load('p1')).records.any((r) => r.id == record.id),
      isFalse,
    );
  });

  test('로그아웃 뒤 늦게 완료된 새로고침이 데이터를 되살리지 않는다', () async {
    final app = AppController(MockCareRepository());
    addTearDown(app.dispose);
    await app.signIn('beneficiary', 'care1234');
    final pending = app.refresh();
    await app.signOut();
    await pending;
    expect(app.user, isNull);
    expect(app.data, isNull);
    expect(app.linkedPeople, isEmpty);
  });

  test('로드 실패 시 이전 자료를 표시하지 않고 재시도로 복구한다', () async {
    final repo = MockCareRepository();
    final app = AppController(repo);
    addTearDown(app.dispose);
    await app.signIn('beneficiary', 'care1234');
    repo.failNextLoad = true;
    await app.refresh();
    expect(app.data, isNull);
    expect(app.error?.code, 'network');
    await app.refresh();
    expect(app.error, isNull);
    expect(app.data, isNotNull);
  });

  test('체험 대상자 가입 후 빈 상태 데이터를 읽을 수 있다', () async {
    final repo = MockCareRepository();
    final user = await repo.register(
      '새 대상자',
      'new_person',
      'password1',
      UserRole.beneficiary,
    );
    final data = await repo.load(user.targetIds.single);
    expect(data.people.single.name, '새 대상자');
    expect(data.appointments, isEmpty);
    expect(data.records, isEmpty);
  });
}
