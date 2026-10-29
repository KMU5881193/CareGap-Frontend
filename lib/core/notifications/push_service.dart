import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background notifications are displayed by the OS. Never log payloads or tokens.
@pragma('vm:entry-point')
Future<void> careGapBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService extends ChangeNotifier {
  static final instance = PushService();
  static const _enabledKey = 'caregap.push.enabled';
  FirebaseMessaging? _messaging;
  SharedPreferences? _prefs;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool configured = false;
  bool enabled = false;
  bool busy = false;
  bool pendingOpen = false;
  int foregroundRevision = 0;
  AuthorizationStatus permission = AuthorizationStatus.notDetermined;
  String? token;
  String? error;
  String? get tokenForTesting => enabled ? token : null;

  bool get allowed =>
      permission == AuthorizationStatus.authorized ||
      permission == AuthorizationStatus.provisional;

  String get status {
    if (!configured) return 'Firebase 프로젝트 연결 대기';
    if (busy) return '기기 알림 상태를 확인하고 있어요';
    if (permission == AuthorizationStatus.denied) return '기기 설정에서 알림을 허용해 주세요';
    if (!enabled) return '푸시 알림이 꺼져 있어요';
    if (!allowed) return '알림 권한을 허용해 주세요';
    if (token == null) return '기기 등록 대기 · 잠시 후 다시 확인해 주세요';
    return '기기 등록 완료 · 테스트 알림 수신 가능';
  }

  Future<void> initialize() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return;
    }
    try {
      _prefs = await SharedPreferences.getInstance();
      enabled = _prefs!.getBool(_enabledKey) ?? false;
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      configured = true;
      FirebaseMessaging.onBackgroundMessage(careGapBackgroundMessage);
      // Foreground uses one privacy-safe in-app banner on both platforms.
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((_) {
          if (!enabled || !allowed) return;
          foregroundRevision++;
          notifyListeners();
        }),
      );
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen((_) {
          pendingOpen = true;
          notifyListeners();
        }),
      );
      _subscriptions.add(
        _messaging!.onTokenRefresh.listen(
          (value) {
            if (!enabled || !allowed) return;
            token = value;
            error = null;
            notifyListeners();
          },
          onError: (Object _) {
            error = '기기 등록을 갱신하지 못했어요. 다시 확인해 주세요.';
            notifyListeners();
          },
        ),
      );
      pendingOpen = await _messaging!.getInitialMessage() != null;
      await refresh();
    } catch (_) {
      configured = false;
      error = 'Firebase 설정 파일을 연결한 뒤 앱을 다시 실행해 주세요.';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!configured || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      permission =
          (await _messaging!.getNotificationSettings()).authorizationStatus;
      await _messaging!.setAutoInitEnabled(enabled && allowed);
      if (enabled && allowed) await _readToken();
      if (!allowed) token = null;
    } catch (_) {
      error = '알림 연결을 확인하지 못했어요. 네트워크와 기기 설정을 확인해 주세요.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _readToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await _messaging!.getAPNSToken() == null) {
      token = null;
      return;
    }
    token = await _messaging!.getToken();
  }

  Future<void> setEnabled(bool value) async {
    if (!configured || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (value) {
        permission = (await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        )).authorizationStatus;
        enabled = allowed;
        await _prefs!.setBool(_enabledKey, enabled);
        await _messaging!.setAutoInitEnabled(enabled);
        if (enabled) await _readToken();
      } else {
        await _messaging!.setAutoInitEnabled(false);
        // Only claim disabled after the server-side FCM token was invalidated.
        await _messaging!.deleteToken();
        enabled = false;
        token = null;
        await _prefs!.setBool(_enabledKey, false);
      }
    } catch (_) {
      error = '설정을 마무리하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void consumeOpen() {
    pendingOpen = false;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
