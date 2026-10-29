import '../errors/app_exception.dart';
import '../models/care_models.dart';
import '../models/frontend_models.dart';
import '../models/user_role.dart';
import 'care_repository.dart';

/// 합성 데이터 전용. 실제 서버 인증·발송·AI 호출을 수행하지 않는다.
class MockCareRepository implements CareRepository {
  MockCareRepository() {
    final today = DateUtilsForMock.today;
    _appointments.addAll([
      Appointment(
        id: 'a1',
        targetId: 'p1',
        start: today.add(const Duration(days: 1, hours: 14)),
        type: VisitType.visit,
        status: AppointmentStatus.confirmed,
        requesterId: 'beneficiary',
        place: '체험 돌봄센터',
        reason: '생활 지원 상담',
      ),
      Appointment(
        id: 'a2',
        targetId: 'p2',
        start: today.add(const Duration(days: 1, hours: 10)),
        type: VisitType.phone,
        status: AppointmentStatus.requested,
        requesterId: 'family2',
        reason: '다음 상담 일정 확인',
      ),
    ]);
    _appointments.add(
      Appointment(
        id: 'a3',
        targetId: 'p1',
        start: today.add(const Duration(hours: 9)),
        type: VisitType.visit,
        status: AppointmentStatus.confirmed,
        requesterId: 'staff',
        place: '체험 돌봄센터',
        reason: '오늘의 생활 상담',
      ),
    );
    _records.addAll([
      CareRecord(
        id: 'r1',
        targetId: 'p1',
        date: today.subtract(const Duration(days: 7)),
        type: VisitType.visit,
        original: '담당자: 최근 식사와 일상은 어떠신가요?\n대상자: 최근 규칙적으로 식사를 하고 있습니다. 산책은 주 2회 하고 있습니다.\n담당자: 다음 상담에서 산책 일정을 함께 확인할게요.',
        summary: '식사와 일상생활에 대해 이야기하고 다음 상담에서 산책 일정을 확인하기로 했습니다.',
        internalNote: '담당자 검토용 합성 내부 메모',
        published: true,
        analysis: const Analysis(
          approved: true,
          summary: '식사와 산책 습관을 확인했습니다.',
          evidence: '산책은 주 2회 하고 있습니다.',
          questions: ['산책을 계속하고 계신가요?'],
          notes: ['건강 상태의 변화나 진단을 판단할 자료는 부족합니다.'],
        ),
      ),
      CareRecord(
        id: 'r2',
        targetId: 'p1',
        date: today.subtract(const Duration(days: 28)),
        type: VisitType.phone,
        original: '복지 서비스 정보를 알고 싶습니다.',
        summary: '이용 가능한 지원 정보를 담당자와 함께 확인하기로 했습니다.',
        published: true,
        analysis: const Analysis(
          approved: true,
          summary: '지원 정보 확인을 희망했습니다.',
          evidence: '복지 서비스 정보를 알고 싶습니다.',
          questions: ['어떤 지원이 가장 필요하신가요?'],
        ),
      ),
      CareRecord(
        id: 'r3',
        targetId: 'p2',
        date: today.subtract(const Duration(days: 2)),
        type: VisitType.visit,
        original: '다음 상담에서 생활 지원 방법을 더 확인하고 싶습니다.',
        summary: '검토 대기 중인 체험 기록',
        internalNote: '대상자에게 공개되지 않는 합성 메모',
        analysis: const Analysis(
          summary: '생활 지원 방법에 대한 추가 확인이 필요합니다.',
          evidence: '생활 지원 방법을 더 확인하고 싶습니다.',
          questions: ['도움이 필요한 일은 무엇인가요?'],
        ),
      ),
    ]);
  }
  final Map<String, AppUser> _users = {
    'beneficiary': const AppUser(
      id: 'beneficiary',
      name: '김하늘',
      role: UserRole.beneficiary,
      targetIds: ['p1'],
    ),
    'family': const AppUser(
      id: 'family',
      name: '김보람',
      role: UserRole.family,
      targetIds: ['p1', 'p2'],
    ),
    'family2': const AppUser(
      id: 'family2',
      name: '박가온',
      role: UserRole.family,
      targetIds: ['p2'],
    ),
    'family_pending': const AppUser(
      id: 'family_pending',
      name: '이새봄',
      role: UserRole.family,
    ),
    'staff': const AppUser(
      id: 'staff',
      name: '이로운',
      role: UserRole.staff,
      targetIds: ['p1', 'p2'],
    ),
    'staff_pending': const AppUser(
      id: 'staff_pending',
      name: '정다정',
      role: UserRole.staff,
      approval: Approval.pending,
    ),
    'staff_rejected': const AppUser(
      id: 'staff_rejected',
      name: '한서로',
      role: UserRole.staff,
      approval: Approval.rejected,
      reason: '체험 반려 사유: 제출 자료 확인이 필요합니다.',
    ),
  };
  final Map<String, String> _passwords = {};
  final Map<String, ProfileData> _profiles = {};
  final Set<String> _withdrawn = {};
  final Set<String> _withdrawnTargets = {};
  final List<HandoverRequest> _handovers = [];
  StaffAvailability _availability = StaffAvailability(
    weekdays: {1, 2, 3, 4, 5, 6, 7},
    hours: {9, 10, 11, 14, 15, 16},
    blockedDates: {},
  );
  final List<Beneficiary> _people = [
    const Beneficiary(
      'p1',
      '김하늘',
      '이로운',
      birthday: '1946. 03. 15.',
      region: '서울시 강서구 화곡동 · 예시',
    ),
    const Beneficiary(
      'p2',
      '박온유',
      '이로운',
      birthday: '1948. 06. 20.',
      region: '서울시 강서구 · 예시',
    ),
  ];
  final List<Appointment> _appointments = [];
  final List<CareRecord> _records = [];
  final List<FamilyLink> _links = [
    const FamilyLink('family', '김보람', 'p1'),
    const FamilyLink('family', '김보람', 'p2'),
    const FamilyLink('family_pending', '이새봄', 'p1', pending: true),
  ];
  final List<CareNotice> _notices = [
    const CareNotice(
      id: 'n1',
      title: '상담 일정이 확정되었어요',
      body: '예정된 상담 일정을 확인해 주세요.',
      kind: 'appointment',
      resourceId: 'a1',
    ),
    const CareNotice(
      id: 'n2',
      title: '상담 결과를 확인해 보세요',
      body: '담당자가 확인한 상담 결과가 등록되었어요.',
      kind: 'record',
      resourceId: 'r1',
    ),
  ];
  final Map<String, Set<String>> _read = {};
  final List<Followup> _followups = [
    const Followup('f1', 'p1', '다음 상담에서 산책 일정 확인'),
  ];
  String? _account;
  int _serial = 10;
  bool failNextLoad = false;
  @override
  Future<AppUser> login(String id, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final user = _users[id];
    if (user == null ||
        _withdrawn.contains(id) ||
        password != (_passwords[id] ?? 'care1234')) {
      throw const AppException('체험 계정과 비밀번호를 확인해 주세요.', code: '401');
    }
    _account = id;
    return user;
  }

  @override
  Future<AppUser> me() async {
    final user = _users[_account];
    if (user == null) throw const AppException('다시 로그인해 주세요.', code: '401');
    return user;
  }

  @override
  Future<void> logout() async {
    _account = null;
  }

  @override
  Future<List<Beneficiary>> linkedPeople() async {
    final user = await me();
    return _people.where((p) => user.targetIds.contains(p.id)).toList();
  }

  @override
  Future<AppUser> register(
    String name,
    String id,
    String password,
    UserRole role,
  ) async {
    if (_users.containsKey(id)) throw const AppException('이미 사용 중인 아이디입니다.');
    final user = AppUser(
      id: id,
      name: name,
      role: role,
      approval: role == UserRole.staff ? Approval.pending : Approval.approved,
      targetIds: role == UserRole.beneficiary ? ['new_$id'] : [],
    );
    _users[id] = user;
    _passwords[id] = password;
    if (role == UserRole.beneficiary) {
      _people.add(Beneficiary('new_$id', name, '미연결'));
    }
    _account = id;
    return user;
  }

  Future<AppUser> _authorized([String? targetId]) async {
    final user = await me();
    if (targetId != null && _withdrawnTargets.contains(targetId)) {
      throw const AppException('탈퇴된 회원의 데이터입니다', code: '410');
    }
    if (user.role == UserRole.staff && user.approval != Approval.approved) {
      throw const AppException('담당자 승인 후 이용할 수 있습니다.', code: '403');
    }
    if (targetId != null && !user.targetIds.contains(targetId)) {
      throw const AppException('연결이 해제되었거나 접근 권한이 없습니다.', code: '403');
    }
    return user;
  }

  Future<AppUser> _staff(String targetId) async {
    final user = await _authorized(targetId);
    if (user.role != UserRole.staff) {
      throw const AppException('담당자만 처리할 수 있습니다.', code: '403');
    }
    return user;
  }

  @override
  Future<Workspace> load(String? targetId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (failNextLoad) {
      failNextLoad = false;
      throw const AppException('연결이 원활하지 않습니다. 다시 시도해 주세요.', code: 'network');
    }
    final user = await _authorized(targetId);
    if (user.role == UserRole.family && targetId == null) {
      throw const AppException('연결된 대상자를 먼저 선택해 주세요.', code: '403');
    }
    final ids = targetId == null ? user.targetIds : [targetId];
    final appointments =
        _appointments.where((a) => ids.contains(a.targetId)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final records =
        _records
            .where(
              (r) =>
                  ids.contains(r.targetId) &&
                  (user.role == UserRole.staff ||
                      (r.published && r.analysis?.approved == true)),
            )
            .map((r) => user.role == UserRole.staff ? r : r.publicView())
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final notices = _notices
        .where(
          (n) => n.kind == 'appointment'
              ? appointments.any((a) => a.id == n.resourceId)
              : records.any((r) => r.id == n.resourceId),
        )
        .map(
          (n) => (_read[user.id]?.contains(n.id) ?? false) ? n.markRead() : n,
        )
        .toList();
    return Workspace(
      people: _people.where((p) => user.targetIds.contains(p.id)).toList(),
      appointments: appointments,
      records: records,
      welfare: const [
        WelfareService(
          'w1',
          '생활 돌봄 지원 (예시)',
          '일상생활에 필요한 지원 정보를 확인해요.',
          '자격·신청 기간·공식 출처 미확인',
        ),
        WelfareService(
          'w2',
          '방문 건강 상담 (예시)',
          '담당 기관에 상담 가능 여부를 문의해요.',
          '대상 조건·기관·필요 서류 미확인',
        ),
        WelfareService(
          'w3',
          '식생활 지원 (예시)',
          '식생활에 도움이 되는 지원 후보예요.',
          '자격·신청 방법·공식 출처 미확인',
        ),
        WelfareService(
          'w4',
          '주거환경 개선 지원 (예시)',
          '안전한 생활 공간을 위한 지원 후보입니다.',
          '대상 조건·기관·신청 기간 미확인',
        ),
      ],
      notices: notices,
      links: user.role == UserRole.beneficiary
          ? _links.where((l) => ids.contains(l.targetId)).toList()
          : [],
      followups: user.role == UserRole.staff
          ? _followups.where((f) => ids.contains(f.targetId)).toList()
          : [],
    );
  }

  void _checkTime(String targetId, DateTime start, {String? except}) {
    if (!_availability.weekdays.contains(start.weekday) ||
        !_availability.hours.contains(start.hour) ||
        start.minute != 0 ||
        _availability.blockedDates.contains(StaffAvailability.dateKey(start))) {
      throw const AppException(
        '담당자가 상담할 수 없는 시간입니다. 다른 시간을 선택해 주세요.',
        code: '409',
      );
    }
    if (!start.isAfter(DateTime.now())) {
      throw const AppException('앞으로의 날짜와 시간을 선택해 주세요.');
    }
    for (final a in _appointments) {
      if (a.id == except ||
          ![
            AppointmentStatus.requested,
            AppointmentStatus.confirmed,
            AppointmentStatus.changeRequested,
          ].contains(a.status)) {
        continue;
      }
      // 체험 담당자는 한 명이다. 같은 담당자의 상담도 겹치지 않도록 한다.
      if (a.start.difference(start).inMinutes.abs() < 60) {
        throw const AppException(
          '선택한 시간에 겹치는 상담이 있습니다. 다른 시간을 선택해 주세요.',
          code: '409',
        );
      }
      if (a.proposedStart != null &&
          a.proposedStart!.difference(start).inMinutes.abs() < 60) {
        throw const AppException(
          '변경 요청 중인 일정과 겹칩니다. 다른 시간을 선택해 주세요.',
          code: '409',
        );
      }
    }
  }

  @override
  Future<Appointment> requestAppointment({
    required String targetId,
    required DateTime start,
    required VisitType type,
    required String reason,
    required String place,
  }) async {
    final user = await _authorized(targetId);
    if (type == VisitType.video || type == VisitType.chat) {
      throw const AppException('현재 방문·전화 상담을 신청할 수 있습니다.');
    }
    if (reason.length > 200 ||
        (type == VisitType.visit && place.trim().isEmpty)) {
      throw const AppException('상담 사유와 방문 장소를 확인해 주세요.');
    }
    if (_people.where((p) => p.id == targetId).firstOrNull?.staffName ==
        '미연결') {
      throw const AppException('상담을 신청하려면 먼저 담당자와 연결해 주세요.');
    }
    _checkTime(targetId, start);
    final a = Appointment(
      id: 'a${_serial++}',
      targetId: targetId,
      start: start,
      type: type,
      status: AppointmentStatus.requested,
      requesterId: user.id,
      reason: reason.trim(),
      place: place.trim(),
    );
    _appointments.add(a);
    return a;
  }

  @override
  Future<void> appointmentAction(
    String id,
    String action, {
    String comment = '',
    DateTime? start,
  }) async {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index < 0) throw const AppException('일정을 찾을 수 없습니다.', code: '404');
    final a = _appointments[index];
    final user = await _authorized(a.targetId);
    final awaiting = [
      AppointmentStatus.requested,
      AppointmentStatus.changeRequested,
    ].contains(a.status);
    if (action == 'accept' || action == 'reject') {
      if (!awaiting ||
          user.id == a.requesterId ||
          (user.role == UserRole.staff) == (a.requesterId == 'staff')) {
        throw const AppException('상대방의 요청만 응답할 수 있습니다.', code: '403');
      }
      if (action == 'accept') {
        final next = a.proposedStart ?? a.start;
        _checkTime(a.targetId, next, except: a.id);
        _appointments[index] = a.copy(
          start: next,
          status: AppointmentStatus.confirmed,
          clearProposal: true,
        );
      } else {
        _appointments[index] = a.copy(
          status: a.status == AppointmentStatus.changeRequested
              ? AppointmentStatus.confirmed
              : AppointmentStatus.rejected,
          clearProposal: true,
        );
      }
    } else if (action == 'cancel') {
      if (![
        AppointmentStatus.requested,
        AppointmentStatus.confirmed,
        AppointmentStatus.changeRequested,
      ].contains(a.status)) {
        throw const AppException('현재 상태에서는 취소할 수 없습니다.');
      }
      if (comment.trim().isEmpty) throw const AppException('취소 사유를 입력해 주세요.');
      _appointments[index] = a.copy(
        status: AppointmentStatus.cancelled,
        comment: comment.trim(),
        clearProposal: true,
      );
    } else if (action == 'change') {
      if (a.status != AppointmentStatus.confirmed || start == null) {
        throw const AppException('확정된 일정의 변경 시간을 선택해 주세요.');
      }
      _checkTime(a.targetId, start, except: a.id);
      _appointments[index] = a.copy(
        status: AppointmentStatus.changeRequested,
        proposedStart: start,
        requesterId: user.id,
      );
    } else if (action == 'complete' || action == 'absent') {
      await _staff(a.targetId);
      if (a.status != AppointmentStatus.confirmed) {
        throw const AppException('확정된 상담만 처리할 수 있습니다.');
      }
      if (a.start.isAfter(DateTime.now())) {
        throw const AppException('상담 예정 시각 이후에 처리해 주세요.');
      }
      if (action == 'complete' && comment.trim().isEmpty) {
        throw const AppException('상담 완료 코멘트를 입력해 주세요.');
      }
      _appointments[index] = a.copy(
        status: action == 'complete'
            ? AppointmentStatus.completed
            : AppointmentStatus.absent,
        comment: comment.trim(),
      );
    } else {
      throw const AppException('지원하지 않는 요청입니다.');
    }
  }

  @override
  Future<CareRecord> saveRecord({
    String? id,
    required String targetId,
    required String original,
    required String note,
    String? appointmentId,
    String followup = '',
    List<MediaInput>? attachments,
    DateTime? date,
    VisitType? type,
  }) async {
    await _staff(targetId);
    if (original.trim().isEmpty) throw const AppException('상담 내용을 입력해 주세요.');
    if (attachments != null &&
        (attachments.length > 4 ||
            attachments.any(
              (f) => f.bytes.isEmpty || f.bytes.length > 20 * 1024 * 1024,
            ))) {
      throw const AppException('첨부는 20MB 이하 시험 파일 4개까지 가능합니다.');
    }
    final oldIndex = _records.indexWhere((r) => r.id == id);
    if (id != null &&
        (oldIndex < 0 || _records[oldIndex].targetId != targetId)) {
      throw const AppException('기록에 접근할 수 없습니다.', code: '403');
    }
    Appointment? appointment;
    if (appointmentId != null) {
      for (final a in _appointments) {
        if (a.id == appointmentId) appointment = a;
      }
      if (appointment == null ||
          appointment.targetId != targetId ||
          appointment.status != AppointmentStatus.completed) {
        throw const AppException('완료된 해당 대상자의 상담만 연결할 수 있습니다.');
      }
    }
    final previous = oldIndex >= 0 ? _records[oldIndex] : null;
    final record = CareRecord(
      id: id ?? 'r${_serial++}',
      targetId: targetId,
      date: date ?? previous?.date ?? appointment?.start ?? DateTime.now(),
      type: type ?? previous?.type ?? appointment?.type ?? VisitType.visit,
      original: original.trim(),
      summary: '담당자 검토 대기',
      internalNote: note.trim(),
      followup: followup.trim(),
      attachments: List.unmodifiable(
        attachments ?? previous?.attachments ?? const [],
      ),
      appointmentId: appointmentId ?? previous?.appointmentId,
    );
    if (oldIndex >= 0) {
      _records[oldIndex] = record;
    } else {
      _records.add(record);
    }
    return record;
  }

  int _recordIndex(String id) {
    final i = _records.indexWhere((r) => r.id == id);
    if (i < 0) throw const AppException('기록을 찾을 수 없습니다.', code: '404');
    return i;
  }

  @override
  Future<void> requestAnalysis(String recordId) async {
    final i = _recordIndex(recordId);
    final before = _records[i];
    await _staff(before.targetId);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await _staff(before.targetId);
    if (!identical(_records[i], before)) {
      throw const AppException('기록이 변경되었습니다. 다시 요청해 주세요.');
    }
    _records[i] = before.withAnalysis(
      Analysis(
        summary: '체험용 분석 초안입니다. 기록을 읽고 요약을 직접 검토해 주세요.',
        evidence: before.original.substring(
          0,
          before.original.length > 80 ? 80 : before.original.length,
        ),
        questions: const ['다음 상담에서 추가로 확인할 사항은 무엇인가요?'],
        notes: const ['실제 AI 분석을 실행하지 않은 예시입니다.', '이전 기록과의 자동 비교 정보가 없습니다.'],
      ),
    );
  }

  @override
  Future<void> approveAnalysis(String recordId, String summary) async {
    final i = _recordIndex(recordId);
    final r = _records[i];
    await _staff(r.targetId);
    if (r.analysis == null || summary.trim().isEmpty) {
      throw const AppException('분석 결과와 검토 내용을 확인해 주세요.');
    }
    _records[i] = r.withAnalysis(
      Analysis(
        summary: summary.trim(),
        evidence: r.analysis!.evidence,
        questions: r.analysis!.questions,
        notes: r.analysis!.notes,
        approved: true,
      ),
    );
    // 검토 승인과 대상자 공개는 분리한다. 새 기록을 자동 공개하지 않는다.
  }

  @override
  Future<void> familyAction(
    String userId,
    String targetId,
    bool approve,
  ) async {
    final actor = await _authorized(targetId);
    if (actor.role != UserRole.beneficiary) {
      throw const AppException('대상자 본인만 연결을 허용하거나 해제할 수 있습니다.', code: '403');
    }
    final i = _links.indexWhere(
      (l) => l.userId == userId && l.targetId == targetId,
    );
    final family = _users[userId];
    if (i < 0 || family == null) throw const AppException('연결 요청을 찾을 수 없습니다.');
    final ids = [...family.targetIds]..remove(targetId);
    if (approve) {
      ids.add(targetId);
      _links[i] = FamilyLink(userId, family.name, targetId);
    } else {
      _links.removeAt(i);
    }
    _users[userId] = AppUser(
      id: family.id,
      name: family.name,
      role: family.role,
      targetIds: ids,
    );
  }

  @override
  Future<void> requestFamilyLink(String code) async {
    final user = await me();
    if (user.role != UserRole.family) {
      throw const AppException('가족 계정으로 요청해 주세요.');
    }
    if (code != 'DEMO123') throw const AppException('체험 연결 코드를 확인해 주세요.');
    if (_links.any((l) => l.userId == user.id && l.targetId == 'p1') ||
        user.targetIds.contains('p1')) {
      throw const AppException('이미 연결되었거나 허용을 기다리는 요청입니다.');
    }
    _links.add(FamilyLink(user.id, user.name, 'p1', pending: true));
  }

  @override
  Future<void> markRead(String noticeId) async {
    final user = await me();
    (_read[user.id] ??= {}).add(noticeId);
  }

  @override
  Future<void> addFollowup(String targetId, String text) async {
    await _staff(targetId);
    if (text.trim().isEmpty) throw const AppException('확인할 내용을 입력해 주세요.');
    _followups.add(Followup('f${_serial++}', targetId, text.trim()));
  }

  @override
  Future<void> toggleFollowup(String id) async {
    final i = _followups.indexWhere((f) => f.id == id);
    if (i < 0) throw const AppException('항목을 찾을 수 없습니다.');
    final f = _followups[i];
    await _staff(f.targetId);
    _followups[i] = Followup(f.id, f.targetId, f.text, done: !f.done);
  }

  @override
  Future<ProfileData> profile() async {
    final user = await me();
    return _profiles[user.id] ??
        ProfileData(name: user.name, phone: '01000000000');
  }

  @override
  Future<void> updateProfile(ProfileData value) async {
    final user = await me();
    if (value.name.trim().isEmpty ||
        !RegExp(r'^01[0-9]{8,9}$').hasMatch(value.phone.replaceAll('-', ''))) {
      throw const AppException('이름과 연락처를 확인해 주세요.');
    }
    _profiles[user.id] = value;
    if (user.role == UserRole.beneficiary) {
      final i = _people.indexWhere((p) => user.targetIds.contains(p.id));
      if (i >= 0) {
        final old = _people[i];
        _people[i] = Beneficiary(
          old.id,
          value.name.trim(),
          old.staffName,
          birthday: value.birthday.isEmpty ? old.birthday : value.birthday,
          region: old.region,
        );
      }
    }

    _users[user.id] = AppUser(
      id: user.id,
      name: value.name.trim(),
      role: user.role,
      approval: user.approval,
      targetIds: user.targetIds,
      reason: user.reason,
    );
  }

  @override
  Future<String> recoverAccount(String phone) async {
    final digits = phone.replaceAll('-', '').trim();
    if (digits == '01000000000' && !_withdrawn.contains('beneficiary')) {
      return 'beneficiary';
    }
    for (final entry in _profiles.entries) {
      if (entry.value.phone.replaceAll('-', '') == digits &&
          !_withdrawn.contains(entry.key)) {
        return entry.key;
      }
    }
    throw const AppException('일치하는 체험 계정을 찾을 수 없어요.');
  }

  @override
  Future<void> resetPassword(String id, String code, String password) async {
    if (!_users.containsKey(id) ||
        _withdrawn.contains(id) ||
        code != '123456') {
      throw const AppException('체험 아이디와 확인 코드 123456을 확인해 주세요.');
    }
    if (password.length < 8) throw const AppException('비밀번호는 8자 이상 입력해 주세요.');
    _passwords[id] = password;
  }

  @override
  Future<void> changePassword(String current, String password) async {
    final user = await me();
    if (current != (_passwords[user.id] ?? 'care1234')) {
      throw const AppException('현재 비밀번호를 확인해 주세요.');
    }
    if (password.length < 8) throw const AppException('비밀번호는 8자 이상 입력해 주세요.');
    _passwords[user.id] = password;
  }

  @override
  Future<void> withdraw(String password) async {
    final user = await me();
    if (password != (_passwords[user.id] ?? 'care1234')) {
      throw const AppException('비밀번호를 확인해 주세요.');
    }
    _withdrawn.add(user.id);
    if (user.role == UserRole.beneficiary) {
      _withdrawnTargets.addAll(user.targetIds);
    }
    // 기록 삭제·보관 정책과 분리한 체험 계정 접근 중지다.
  }

  @override
  Future<StaffAvailability> availability() async {
    await _authorized();
    return _availability;
  }

  @override
  Future<void> saveAvailability(StaffAvailability value) async {
    final user = await _authorized();
    if (user.role != UserRole.staff) {
      throw const AppException('담당자만 변경할 수 있어요.', code: '403');
    }
    if (value.weekdays.any((v) => v < 1 || v > 7) ||
        value.hours.any((v) => v < 0 || v > 23)) {
      throw const AppException('요일과 시간을 확인해 주세요.');
    }
    _availability = StaffAvailability(
      weekdays: {...value.weekdays},
      hours: {...value.hours},
      blockedDates: {...value.blockedDates},
    );
  }

  @override
  Future<ConversionResult> convertMedia(MediaInput input) async {
    final user = await _authorized();
    if (user.role != UserRole.staff) {
      throw const AppException('담당자만 변환을 요청할 수 있어요.', code: '403');
    }
    if (input.bytes.isEmpty || input.bytes.length > 20 * 1024 * 1024) {
      throw const AppException('체험 파일은 20MB 이하로 선택해 주세요.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final current = await me();
    if (current.id != user.id) {
      throw const AppException('계정이 변경되었습니다.', code: '401');
    }
    return ConversionResult(
      input.kind == 'image'
          ? '[사진 문자 추출 예시]\n선택한 파일을 실제로 분석한 결과가 아닙니다. 상담 원문을 확인하고 직접 수정해 주세요.'
          : '[음성 변환 예시]\n담당자: 오늘 어떤 도움이 필요하신가요?\n대상자: 생활 지원 방법을 함께 확인하고 싶습니다.\n\n※ 선택한 음성의 실제 변환 결과가 아닙니다.',
    );
  }

  @override
  Future<void> requestHandover(String recordId, String receiver) async {
    final i = _recordIndex(recordId);
    await _staff(_records[i].targetId);
    if (receiver.trim().isEmpty) throw const AppException('전달받을 담당자를 선택해 주세요.');
    _handovers.add(HandoverRequest(recordId, receiver, DateTime.now()));
    // 인계 요청만 기록한다. 승인 정책 확정 전 접근 권한을 부여하지 않는다.
  }

  @override
  Future<List<HandoverRequest>> handovers() async {
    final user = await _authorized();
    if (user.role != UserRole.staff) return [];
    return [..._handovers];
  }

  @override
  Future<void> submitQualification(MediaInput input) async {
    final user = await me();
    if (user.role != UserRole.staff) {
      throw const AppException('담당자 계정이 필요해요.', code: '403');
    }
    if (input.bytes.isEmpty || input.bytes.length > 20 * 1024 * 1024) {
      throw const AppException('자료를 확인해 주세요.');
    }
    _users[user.id] = AppUser(
      id: user.id,
      name: user.name,
      role: user.role,
      approval: Approval.pending,
      targetIds: user.targetIds,
    );
  }
}

abstract final class DateUtilsForMock {
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
