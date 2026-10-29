import 'package:flutter/widgets.dart';

import 'app_controller.dart';

class CareScope extends InheritedNotifier<AppController> {
  const CareScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CareScope>();
    assert(scope != null, 'CareScope가 필요합니다.');
    return scope!.notifier!;
  }
}
