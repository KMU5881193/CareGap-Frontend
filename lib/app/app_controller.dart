import 'package:flutter/foundation.dart';

import '../core/data/care_repository.dart';
import '../core/errors/app_exception.dart';
import '../core/models/care_models.dart';
import '../core/models/user_role.dart';
import '../core/notifications/push_service.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository);
  final CareRepository repository;
  AppUser? user;
  Workspace? data;
  List<Beneficiary> linkedPeople = [];
  String? selectedTargetId;
  AppException? error;
  bool loading = false;
  bool workspaceReady = false;
  double fontScale = 1;
  bool highContrast = false;
  void setHighContrast(bool value) {
    highContrast = value;
    notifyListeners();
  }

  final Map<String, Map<String, bool>> _preferences = {};
  Map<String, bool> get notificationPreferences => _preferences.putIfAbsent(
    user?.id ?? 'guest',
    () => {'예약 알림': true, '상담 결과 알림': true},
  );
  int _generation = 0;
  final Map<String, Set<String>> _favorites = {};
  Set<String> get favoriteServices =>
      _favorites.putIfAbsent(user?.id ?? 'guest', () => {});
  void toggleFavorite(String id) {
    favoriteServices.contains(id)
        ? favoriteServices.remove(id)
        : favoriteServices.add(id);
    notifyListeners();
  }

  bool get isStaff => user?.role == UserRole.staff;
  bool get restricted =>
      user != null &&
      ((isStaff && user!.approval != Approval.approved) ||
          (user!.role == UserRole.family && user!.targetIds.isEmpty));
  bool get needsTarget =>
      user?.role == UserRole.family && !restricted && selectedTargetId == null;
  String personName(String id) =>
      data?.people.where((p) => p.id == id).firstOrNull?.name ?? '대상자';
  Future<void> signIn(String id, String password) async {
    final next = await repository.login(id.trim(), password);
    user = next;
    workspaceReady = false;
    selectedTargetId = next.role == UserRole.beneficiary
        ? next.targetIds.firstOrNull
        : null;
    data = null;
    error = null;
    notifyListeners();
    await refresh();
  }

  Future<void> register(
    String name,
    String id,
    String password,
    UserRole role,
  ) async {
    user = await repository.register(name.trim(), id.trim(), password, role);
    workspaceReady = false;
    selectedTargetId = role == UserRole.beneficiary
        ? user!.targetIds.firstOrNull
        : null;
    data = null;
    error = null;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    loading = true;
    data = null;
    error = null;
    notifyListeners();
    try {
      final next = await repository.me();
      if (generation != _generation) return;
      user = next;
      final people = await repository.linkedPeople();
      if (generation != _generation) return;
      linkedPeople = people;
      if (selectedTargetId != null &&
          !next.targetIds.contains(selectedTargetId)) {
        selectedTargetId = null;
      }
      if (next.role == UserRole.beneficiary) {
        selectedTargetId = next.targetIds.firstOrNull;
      }
      if (restricted || needsTarget) return;
      final loaded = await repository.load(selectedTargetId);
      if (generation != _generation) return;
      data = loaded;
      workspaceReady = true;
    } on AppException catch (e) {
      if (generation != _generation) return;
      error = e;
      if (e.code == '401') {
        user = null;
        linkedPeople = [];
        selectedTargetId = null;
        workspaceReady = false;
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectTarget(String id) async {
    if (!(user?.targetIds.contains(id) ?? false)) {
      throw const AppException('접근 권한이 없습니다.', code: '403');
    }
    selectedTargetId = id;
    workspaceReady = false;
    await refresh();
  }

  Future<T> mutate<T>(Future<T> Function(CareRepository) operation) async {
    final actor = user?.id;
    final target = selectedTargetId;
    final result = await operation(repository);
    if (user?.id == actor && actor != null && target == selectedTargetId) {
      await refresh();
    }
    return result;
  }

  Future<void> signOut() async {
    ++_generation;
    user = null;
    workspaceReady = false;
    linkedPeople = [];
    data = null;
    selectedTargetId = null;
    error = null;
    loading = false;
    notifyListeners();
    PushService.instance.consumeOpen();
    await Future.wait([
      repository.logout(),
      if (PushService.instance.enabled) PushService.instance.setEnabled(false),
    ]);
  }

  void expireSession() {
    ++_generation;
    user = null;
    data = null;
    linkedPeople = [];
    selectedTargetId = null;
    workspaceReady = false;
    loading = false;
    error = const AppException(
      '로그인이 만료됐어요. 서버가 재시작됐다면 다시 가입해 주세요.',
      code: '401',
    );
    notifyListeners();
  }

  void setFontScale(double value) {
    fontScale = value;
    notifyListeners();
  }

  void setPreference(String key, bool value) {
    notificationPreferences[key] = value;
    notifyListeners();
  }
}
