import 'user_role.dart';
import 'frontend_models.dart';

enum Approval { approved, pending, rejected }

enum VisitType {
  visit('방문 상담'),
  phone('전화 상담'),
  video('영상 상담'),
  chat('채팅 상담');

  const VisitType(this.label);
  final String label;
}

enum AppointmentStatus {
  requested('요청 대기'),
  confirmed('확정'),
  changeRequested('변경 요청'),
  rejected('거절'),
  cancelled('취소'),
  completed('완료'),
  absent('불참');

  const AppointmentStatus(this.label);
  final String label;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.approval = Approval.approved,
    this.targetIds = const [],
    this.reason,
  });
  final String id, name;
  final UserRole role;
  final Approval approval;
  final List<String> targetIds;
  final String? reason;
}

class Beneficiary {
  const Beneficiary(
    this.id,
    this.name,
    this.staffName, {
    this.birthday = '',
    this.region = '',
  });
  final String id, name, staffName, birthday, region;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.targetId,
    required this.start,
    required this.type,
    required this.status,
    required this.requesterId,
    this.reason = '',
    this.place = '',
    this.proposedStart,
    this.comment = '',
  });
  final String id, targetId, requesterId, reason, place, comment;
  final DateTime start;
  final VisitType type;
  final AppointmentStatus status;
  final DateTime? proposedStart;
  Appointment copy({
    DateTime? start,
    AppointmentStatus? status,
    String? requesterId,
    DateTime? proposedStart,
    bool clearProposal = false,
    String? comment,
  }) => Appointment(
    id: id,
    targetId: targetId,
    start: start ?? this.start,
    type: type,
    status: status ?? this.status,
    requesterId: requesterId ?? this.requesterId,
    reason: reason,
    place: place,
    proposedStart: clearProposal ? null : (proposedStart ?? this.proposedStart),
    comment: comment ?? this.comment,
  );
}

class Analysis {
  const Analysis({
    required this.summary,
    required this.evidence,
    required this.questions,
    this.approved = false,
    this.notes = const [],
  });
  final String summary, evidence;
  final List<String> questions, notes;
  final bool approved;
}

class CareRecord {
  const CareRecord({
    required this.id,
    required this.targetId,
    required this.date,
    required this.type,
    required this.original,
    required this.summary,
    this.appointmentId,
    this.internalNote = '',
    this.followup = '',
    this.attachments = const [],
    this.published = false,
    this.analysis,
  });
  final String id, targetId, original, summary, internalNote, followup;
  final List<MediaInput> attachments;
  final String? appointmentId;
  final DateTime date;
  final VisitType type;
  final bool published;
  final Analysis? analysis;
  CareRecord withAnalysis(Analysis value) => CareRecord(
    id: id,
    targetId: targetId,
    date: date,
    type: type,
    original: original,
    summary: summary,
    appointmentId: appointmentId,
    internalNote: internalNote,
    followup: followup,
    attachments: attachments,
    published: published,
    analysis: value,
  );
  CareRecord publicView() => CareRecord(
    id: id,
    targetId: targetId,
    date: date,
    type: type,
    original: '',
    summary: summary,
    published: published,
    appointmentId: appointmentId,
    analysis: analysis?.approved == true ? analysis : null,
  );
}

class WelfareService {
  const WelfareService(this.id, this.name, this.description, this.requirements);
  final String id, name, description, requirements;
  String get category => id == 'w1'
      ? '돌봄'
      : id == 'w2'
      ? '건강'
      : id == 'w3'
      ? '식사'
      : '주거';
  String get asset => id == 'w1'
      ? 'family_care_v1.png'
      : id == 'w2'
      ? 'care_hero_v1.png'
      : id == 'w3'
      ? 'meal_support_v1.png'
      : 'welfare_home_v1.png';
}

class CareNotice {
  const CareNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.resourceId,
    this.read = false,
  });
  final String id, title, body, kind;
  final String? resourceId;
  final bool read;
  CareNotice markRead() => CareNotice(
    id: id,
    title: title,
    body: body,
    kind: kind,
    resourceId: resourceId,
    read: true,
  );
}

class FamilyLink {
  const FamilyLink(
    this.userId,
    this.name,
    this.targetId, {
    this.pending = false,
  });
  final String userId, name, targetId;
  final bool pending;
}

class Followup {
  const Followup(this.id, this.targetId, this.text, {this.done = false});
  final String id, targetId, text;
  final bool done;
}

class Workspace {
  const Workspace({
    required this.people,
    required this.appointments,
    required this.records,
    required this.welfare,
    required this.notices,
    required this.links,
    required this.followups,
  });
  final List<Beneficiary> people;
  final List<Appointment> appointments;
  final List<CareRecord> records;
  final List<WelfareService> welfare;
  final List<CareNotice> notices;
  final List<FamilyLink> links;
  final List<Followup> followups;
}
