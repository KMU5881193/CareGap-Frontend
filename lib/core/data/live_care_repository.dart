import 'dart:convert';

import '../api/api_client.dart';
import '../errors/app_exception.dart';
import '../models/care_models.dart';
import '../models/frontend_models.dart';
import '../models/user_role.dart';
import 'care_repository.dart';

class LiveCareRepository implements CareRepository {
  LiveCareRepository(this.api);
  final ApiClient api;
  AppUser? user;
  int _epoch = 0;
  void _guard(int epoch) {
    if (epoch != _epoch) {
      throw const AppException('세션이 변경되어 이전 요청 결과를 폐기했습니다.', code: 'CANCELLED');
    }
  }

  List<Json> persons = [],
      appointments = [],
      recordVersions = [],
      tasks = [],
      notices = [];
  final Map<String, Json> analyses = {};
  final Map<String, List<Json>> candidates = {};
  final Map<String, String> _analysisKeys = {};
  Json? healthData;
  Future<Json> health() async =>
      healthData = object(await api.request('GET', '/health', auth: false));
  Future<AppUser> _actor(Json actor, String name) async {
    if (actor['role'] != 'staff') {
      throw const AppException('현재 서버는 합성 담당자 계정만 지원합니다.');
    }
    return user = AppUser(
      id: requiredId(actor, 'user_id'),
      name: name,
      role: UserRole.staff,
    );
  }

  @override
  Future<AppUser> login(String id, String password) async {
    api.clearSession();
    clearData();
    final epoch = _epoch;
    final d = object(
      await api.request(
        'POST',
        '/api/auth/login',
        body: {'identifier': id, 'password': password},
        auth: false,
      ),
    );
    _guard(epoch);
    api.token = requiredId(d, 'access_token');
    api.expiresAt = DateTime.now().add(
      Duration(seconds: (d['expires_in'] as num).toInt()),
    );
    return _actor(object(d['actor']), id);
  }

  @override
  Future<AppUser> register(
    String name,
    String id,
    String password,
    UserRole role,
  ) async {
    if (role != UserRole.staff) unsupported();
    await api.request(
      'POST',
      '/api/auth/register',
      body: {'identifier': id, 'password': password},
      auth: false,
    );
    return login(id, password);
  }

  @override
  Future<AppUser> me() async {
    final epoch = _epoch;
    final value = object(await api.request('GET', '/api/auth/me'));
    _guard(epoch);
    return _actor(value, user?.name ?? '합성 담당자');
  }

  void clearData() {
    _epoch++;
    persons = [];
    appointments = [];
    recordVersions = [];
    tasks = [];
    notices = [];
    analyses.clear();
    candidates.clear();
    _analysisKeys.clear();
    user = null;
  }

  @override
  Future<void> logout() async {
    final request = api.token == null
        ? Future<dynamic>.value()
        : api.request('POST', '/api/auth/logout', body: {});
    api.clearSession();
    clearData();
    await request;
  }

  @override
  Future<List<Beneficiary>> linkedPeople() async {
    final epoch = _epoch;
    final value = objects(await api.request('GET', '/api/persons'));
    _guard(epoch);
    persons = value;
    return [
      for (final p in persons)
        Beneficiary(
          requiredId(p, 'person_id'),
          label(p['person_id']),
          '합성 담당자',
        ),
    ];
  }

  String label(Object? id) =>
      '합성 대상자 ${id.toString().substring(0, id.toString().length < 6 ? id.toString().length : 6)}';
  Future<String> createPerson() async => requiredId(
    object(await api.request('POST', '/api/persons', body: {})),
    'person_id',
  );
  @override
  Future<Workspace> load(String? targetId) async {
    final epoch = _epoch;
    final loadedPeople = List<Json>.of(persons);
    final loadedAppointments = objects(
      await api.request('GET', '/api/appointments'),
    );
    final loadedNotices = objects(
      await api.request('GET', '/api/notifications'),
    );
    final versions = <Json>[], followups = <Json>[];
    for (final person in loadedPeople) {
      final id = requiredId(person, 'person_id');
      versions.addAll(
        objects(await api.request('GET', '/api/records?person_id=$id')),
      );
      followups.addAll(
        objects(await api.request('GET', '/api/follow-ups?person_id=$id')),
      );
    }
    _guard(epoch);
    appointments = loadedAppointments;
    notices = loadedNotices;
    recordVersions = versions;
    tasks = followups;
    return Workspace(
      people: [
        for (final p in persons)
          Beneficiary(p['person_id'], label(p['person_id']), '합성 담당자'),
      ],
      appointments: const [],
      records: const [],
      welfare: const [],
      links: const [],
      notices: [
        for (final n in notices)
          CareNotice(
            id: n['notification_id'],
            title: n['title'],
            body: n['body'],
            kind: 'manual',
            read: n['read_at'] != null,
          ),
      ],
      followups: [
        for (final t in tasks)
          Followup(
            t['follow_up_id'],
            t['person_id'],
            t['title'],
            done: t['status'] != 'open',
          ),
      ],
    );
  }

  List<Json> recordsFor(String personId) =>
      recordVersions.where((r) => r['person_id'] == personId).toList();
  List<Json> latestRecords(String personId) {
    final latest = <String, Json>{};
    for (final r in recordsFor(personId)) {
      latest[requiredId(r, 'consultation_id')] = r;
    }
    return latest.values.toList();
  }

  Future<Json> writeRecord(
    String personId,
    String text, {
    Json? previous,
  }) async => object(
    await api.request(
      'POST',
      previous == null
          ? '/api/records'
          : '/api/records/${previous['consultation_id']}/versions',
      body: previous == null
          ? {'person_id': personId, 'text': text}
          : {
              'expected_record_version_id': previous['record_version_id'],
              'text': text,
            },
    ),
  );
  Future<Json> book(String personId, DateTime start, DateTime end) async =>
      object(
        await api.request(
          'POST',
          '/api/appointments',
          body: {
            'person_id': personId,
            'starts_at': start.toUtc().toIso8601String(),
            'ends_at': end.toUtc().toIso8601String(),
          },
        ),
      );
  Future<void> bookingAction(Json row, String action) async {
    await api.request(
      'POST',
      '/api/appointments/${row['appointment_id']}/actions',
      body: {'action': action, 'expected_status': row['status']},
    );
  }

  Json ref(Json record) => {
    'consultation_id': record['consultation_id'],
    'record_version_id': record['record_version_id'],
  };
  Future<Json> analyze(String personId, Json past, Json current) async {
    final epoch = _epoch;
    final body = {
      'person_id': personId,
      'past': [ref(past)],
      'current': ref(current),
    };
    final signature = jsonEncode(body);
    final key = _analysisKeys.putIfAbsent(signature, requestKey);
    final result = object(
      await api.request('POST', '/api/analyses', body: body, key: key),
    );
    _guard(epoch);
    analyses[requiredId(result, 'id')] = result;
    // Network retries keep the key; an explicitly failed run may start anew.
    if (result['status'] == 'failed') _analysisKeys.remove(signature);
    return result;
  }

  Future<Json> getAnalysis(String id) async {
    final epoch = _epoch;
    final value = object(await api.request('GET', '/api/analyses/$id'));
    _guard(epoch);
    analyses[id] = value;
    return value;
  }

  Future<Json> review(Json analysis, String action, {Json? draft}) async {
    final epoch = _epoch;
    final id = requiredId(analysis, 'id');
    final value = object(
      await api.request(
        'POST',
        '/api/analysis-reviews/$id',
        body: {
          'action': action,
          'expected_version': analysis['version'],
          'draft': ?draft,
        },
      ),
    );
    _guard(epoch);
    analyses[id] = value;
    candidates.remove(id);
    return value;
  }

  Future<Json> recommend(Json analysis, List<Json> confirmations) async {
    final epoch = _epoch;
    final value = object(
      await api.request(
        'POST',
        '/api/welfare-recommendations',
        body: {
          'analysis_id': analysis['id'],
          'expected_analysis_version': analysis['version'],
          'confirmations': confirmations,
        },
      ),
    );
    _guard(epoch);
    candidates[analysis['id']] = objects(value['candidates']);
    return value;
  }

  Future<Json> createJob(
    String source,
    String personId,
    MediaInput file,
    String key,
  ) async => object(
    await api.request(
      'POST',
      '/api/$source/jobs',
      body: {
        'person_id': personId,
        'request_key': key,
        'filename': file.name,
        'mimeType': source == 'stt'
            ? 'audio/wav'
            : file.bytes.length > 2 && file.bytes[0] == 137
            ? 'image/png'
            : 'image/jpeg',
        'base64': base64Encode(file.bytes),
      },
    ),
  );
  Future<Json> getJob(String source, String id) async =>
      object(await api.request('GET', '/api/$source/jobs/$id'));
  Future<Json> correctJob(
    String source,
    Json job,
    String text, {
    List<Json>? segments,
  }) async => object(
    await api.request(
      'POST',
      '/api/$source/jobs/${job['id']}/corrections',
      body: {
        'expected_version': job['version'],
        if (source == 'ocr') 'text': text,
        if (source == 'stt') 'segments': segments,
      },
    ),
  );
  Future<Json> confirmJob(String source, Json job) async => object(
    await api.request(
      'POST',
      '/api/$source/jobs/${job['id']}/confirmation',
      body: {'expected_version': job['version']},
    ),
  );
  Future<Json> importJob(String source, Json job) async => object(
    await api.request(
      'POST',
      '/api/records/import',
      body: {'source': source, 'job_id': job['id']},
    ),
  );
  Future<void> createNotice(String title, String body) async {
    await api.request(
      'POST',
      '/api/notifications',
      body: {'title': title, 'body': body},
    );
  }

  @override
  Future<void> markRead(String noticeId) async {
    await api.request('POST', '/api/notifications/$noticeId/read', body: {});
  }

  @override
  Future<void> addFollowup(String targetId, String text) async {
    await api.request(
      'POST',
      '/api/follow-ups',
      body: {'person_id': targetId, 'title': text},
    );
  }

  Future<void> taskAction(Json task, String action) async {
    await api.request(
      'POST',
      '/api/follow-ups/${task['follow_up_id']}/actions',
      body: {'action': action, 'expected_status': task['status']},
    );
  }

  @override
  Future<void> toggleFollowup(String id) async =>
      taskAction(tasks.firstWhere((t) => t['follow_up_id'] == id), 'complete');
  Never unsupported() => throw const AppException(
    '현재 통합 서버에 이 기능의 API가 없습니다. 변경 사항은 저장되지 않았습니다.',
    code: 'UNSUPPORTED',
  );
  @override
  Future<Appointment> requestAppointment({
    required String targetId,
    required DateTime start,
    required VisitType type,
    required String reason,
    required String place,
  }) async => unsupported();
  @override
  Future<void> appointmentAction(
    String id,
    String action, {
    String comment = '',
    DateTime? start,
  }) async => unsupported();
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
  }) async => unsupported();
  @override
  Future<void> requestAnalysis(String recordId) async => unsupported();
  @override
  Future<void> approveAnalysis(String recordId, String summary) async =>
      unsupported();
  @override
  Future<void> familyAction(
    String userId,
    String targetId,
    bool approve,
  ) async => unsupported();
  @override
  Future<void> requestFamilyLink(String code) async => unsupported();
  @override
  Future<ProfileData> profile() async => unsupported();
  @override
  Future<void> updateProfile(ProfileData profile) async => unsupported();
  @override
  Future<String> recoverAccount(String phone) async => unsupported();
  @override
  Future<void> resetPassword(String id, String code, String password) async =>
      unsupported();
  @override
  Future<void> changePassword(String current, String password) async =>
      unsupported();
  @override
  Future<void> withdraw(String password) async => unsupported();
  @override
  Future<StaffAvailability> availability() async => unsupported();
  @override
  Future<void> saveAvailability(StaffAvailability value) async => unsupported();
  @override
  Future<ConversionResult> convertMedia(MediaInput input) async =>
      unsupported();
  @override
  Future<void> requestHandover(String recordId, String receiver) async =>
      unsupported();
  @override
  Future<List<HandoverRequest>> handovers() async => unsupported();
  @override
  Future<void> submitQualification(MediaInput input) async => unsupported();
}
