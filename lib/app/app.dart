import 'package:flutter_localizations/flutter_localizations.dart';

import 'widgets/app_widgets.dart';

import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/data/mock_care_repository.dart';
import '../core/data/live_care_repository.dart';
import '../core/api/api_client.dart';
import '../features/live/presentation/live_shell_page.dart';
import '../core/notifications/push_service.dart';
import '../features/notifications/presentation/pages/notification_settings_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/connections/presentation/pages/access_restricted_page.dart';
import '../features/connections/presentation/pages/beneficiary_selection_page.dart';
import '../features/home/presentation/pages/main_shell_page.dart';
import 'app_controller.dart';
import 'care_scope.dart';
import 'theme/app_theme.dart';

class CaregapApp extends StatefulWidget {
  const CaregapApp({super.key, this.controller});
  final AppController? controller;
  @override
  State<CaregapApp> createState() => _CaregapAppState();
}

class _CaregapAppState extends State<CaregapApp> with WidgetsBindingObserver {
  late final app =
      widget.controller ??
      AppController(
        AppConfig.useMock
            ? MockCareRepository()
            : LiveCareRepository(ApiClient(AppConfig.backendUrl)),
      );
  final navigator = GlobalKey<NavigatorState>();
  final messenger = GlobalKey<ScaffoldMessengerState>();
  int _foregroundRevision = 0;
  bool _openingPush = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (app.repository case final LiveCareRepository repo) {
      repo.api.onUnauthorized = () {
        repo.clearData();
        app.expireSession();
      };
    }
    PushService.instance.addListener(_onPush);
    app.addListener(_onPush);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPush());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PushService.instance.removeListener(_onPush);
    app.removeListener(_onPush);
    if (widget.controller == null) app.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && app.user != null) app.refresh();
    if (state == AppLifecycleState.resumed) PushService.instance.refresh();
  }

  void _onPush() {
    if (!mounted) return;
    final push = PushService.instance;
    if (push.foregroundRevision != _foregroundRevision) {
      _foregroundRevision = push.foregroundRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        messenger.currentState?.showSnackBar(
          const SnackBar(content: Text('돌봄틈새 AI 알림이 도착했어요. 앱에서 내용을 확인해 주세요.')),
        );
      });
    }
    if (!push.pendingOpen ||
        _openingPush ||
        app.user == null ||
        !app.workspaceReady ||
        app.restricted ||
        app.needsTarget) {
      return;
    }
    _openingPush = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openingPush = false;
      if (!mounted ||
          app.user == null ||
          !app.workspaceReady ||
          app.restricted ||
          app.needsTarget ||
          navigator.currentState == null) {
        return;
      }
      push.consumeOpen();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationSettingsPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => CareScope(
    controller: app,
    child: AnimatedBuilder(
      animation: app,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigator,
        scaffoldMessengerKey: messenger,
        title: '돌봄틈새 AI',
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        theme: app.highContrast ? AppTheme.highContrast : AppTheme.light,
        highContrastTheme: AppTheme.highContrast,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return ColoredBox(
            color: const Color(0xFFEAF4EE),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: MediaQuery(
                  data: media.copyWith(
                    size: Size(
                      media.size.width > 480 ? 480 : media.size.width,
                      media.size.height,
                    ),
                    textScaler: _CareTextScaler(
                      media.textScaler,
                      app.fontScale,
                    ),
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        },
        home: const _SessionGate(),
      ),
    ),
  );
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    if (app.user == null) return const WelcomePage();
    if (app.loading && app.data == null && !app.workspaceReady) {
      return const SplashPage();
    }
    if (app.error != null) {
      return Scaffold(
        body: SafeArea(
          child: PageBody(
            children: [
              ErrorView(message: app.error!.message, onRetry: app.refresh),
              AsyncActionButton(
                label: '로그아웃',
                secondary: true,
                action: app.signOut,
              ),
            ],
          ),
        ),
      );
    }
    if (app.restricted) return const AccessRestrictedPage();
    if (app.needsTarget) return const BeneficiarySelectionPage();
    if (app.repository is LiveCareRepository) return const LiveShellPage();
    return const MainShellPage();
  }
}

class _CareTextScaler extends TextScaler {
  const _CareTextScaler(this.base, this.factor);
  final TextScaler base;
  final double factor;
  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;
  @override
  double get textScaleFactor => scale(16) / 16;
}
