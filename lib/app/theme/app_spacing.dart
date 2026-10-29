import 'package:flutter/widgets.dart';

/// 화면과 컴포넌트에서 공통으로 사용하는 간격·크기.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double pageHorizontal = 20;
  static const double minTouchTarget = 48;
  static const double buttonRadius = 26;
  static const double inputRadius = 12;
  static const double cardRadius = 16;
  static const double sheetRadius = 20;

  static const pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: xl,
  );
}
