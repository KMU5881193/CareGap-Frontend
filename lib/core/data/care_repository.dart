import '../models/care_models.dart';
import '../models/frontend_models.dart';
import '../models/user_role.dart';

/// API 합의 후 서버 구현으로 교체할 비동기 데이터 경계.
abstract interface class CareRepository {
  Future<AppUser> login(String id, String password);
  Future<AppUser> me();
  Future<List<Beneficiary>> linkedPeople();
  Future<void> logout();
  Future<AppUser> register(
    String name,
    String id,
    String password,
    UserRole role,
  );
  Future<Workspace> load(String? targetId);
  Future<Appointment> requestAppointment({
    required String targetId,
    required DateTime start,
    required VisitType type,
    required String reason,
    required String place,
  });
  Future<void> appointmentAction(
    String id,
    String action, {
    String comment = '',
    DateTime? start,
  });
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
  });
  Future<void> requestAnalysis(String recordId);
  Future<void> approveAnalysis(String recordId, String summary);
  Future<void> familyAction(String userId, String targetId, bool approve);
  Future<void> requestFamilyLink(String code);
  Future<void> markRead(String noticeId);
  Future<void> addFollowup(String targetId, String text);
  Future<void> toggleFollowup(String id);

  Future<ProfileData> profile();
  Future<void> updateProfile(ProfileData profile);
  Future<String> recoverAccount(String phone);
  Future<void> resetPassword(String id, String code, String password);
  Future<void> changePassword(String current, String password);
  Future<void> withdraw(String password);
  Future<StaffAvailability> availability();
  Future<void> saveAvailability(StaffAvailability value);
  Future<ConversionResult> convertMedia(MediaInput input);
  Future<void> requestHandover(String recordId, String receiver);
  Future<List<HandoverRequest>> handovers();

  Future<void> submitQualification(MediaInput input);
}
