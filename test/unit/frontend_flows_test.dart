import 'dart:typed_data';

import 'package:caregap_app/core/data/mock_care_repository.dart';
import 'package:caregap_app/core/errors/app_exception.dart';
import 'package:caregap_app/core/models/care_models.dart';
import 'package:caregap_app/core/models/frontend_models.dart';
import 'package:caregap_app/core/media/media_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('프로필과 비밀번호 변경이 현재 사용자·다음 로그인에 반영된다', () async {
    final repo = MockCareRepository();
    await repo.login('beneficiary', 'care1234');
    await repo.updateProfile(
      const ProfileData(name: '시험 이름', phone: '01000000000'),
    );
    expect((await repo.me()).name, '시험 이름');
    expect((await repo.load('p1')).people.single.name, '시험 이름');
    await expectLater(
      repo.changePassword('wrong', 'newpass123'),
      throwsA(isA<AppException>()),
    );
    await repo.changePassword('care1234', 'newpass123');
    await repo.logout();
    await expectLater(
      repo.login('beneficiary', 'care1234'),
      throwsA(isA<AppException>()),
    );
    expect((await repo.login('beneficiary', 'newpass123')).name, '시험 이름');
  });

  test('담당자 휴무는 상담 요청에서도 다시 검증된다', () async {
    final repo = MockCareRepository();
    await repo.login('staff', 'care1234');
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day + 12, 14);
    await repo.saveAvailability(
      StaffAvailability(
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        hours: {14},
        blockedDates: {StaffAvailability.dateKey(day)},
      ),
    );
    await repo.login('beneficiary', 'care1234');
    await expectLater(
      repo.requestAppointment(
        targetId: 'p1',
        start: day,
        type: VisitType.phone,
        reason: '',
        place: '',
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('첨부 파일은 담당자 기록에 보관하고 공개 응답에는 포함하지 않는다', () async {
    final repo = MockCareRepository();
    await repo.login('staff', 'care1234');
    final file = MediaInput(
      name: 'sample.wav',
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      kind: 'audio',
    );
    final record = await repo.saveRecord(
      targetId: 'p1',
      original: '시험 상담 원문',
      note: '',
      attachments: [file],
    );
    expect(record.attachments.single.name, file.name);
    expect(record.publicView().attachments, isEmpty);
    final edited = await repo.saveRecord(
      id: record.id,
      targetId: 'p1',
      original: '수정한 시험 상담',
      note: '',
    );
    expect(edited.attachments.single.bytes, file.bytes);
    final removed = await repo.saveRecord(
      id: record.id,
      targetId: 'p1',
      original: '첨부 삭제',
      note: '',
      attachments: [],
    );
    expect(removed.attachments, isEmpty);
  });

  test('탈퇴 대상자는 연결 가족에게도 접근 중지된다', () async {
    final repo = MockCareRepository();
    await repo.login('beneficiary', 'care1234');
    await repo.withdraw('care1234');
    await expectLater(
      repo.login('beneficiary', 'care1234'),
      throwsA(isA<AppException>()),
    );
    await repo.login('family', 'care1234');
    await expectLater(repo.load('p1'), throwsA(isA<AppException>()));
  });

  test('PCM 녹음은 재생 가능한 mono 16kHz WAV 헤더로 감싼다', () {
    final pcm = Uint8List.fromList([0, 1, 2, 3]);
    final wav = AudioCapture.makeWav(pcm),
        header = ByteData.sublistView(AudioCapture.makeWav(pcm));
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint32(24, Endian.little), 16000);
    expect(header.getUint32(40, Endian.little), pcm.length);
    expect(wav.sublist(44), pcm);
  });
}
