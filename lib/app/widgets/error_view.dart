import 'package:flutter/material.dart';

import 'empty_view.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => EmptyView(
    title: '정보를 불러오지 못했어요',
    message: message,
    icon: Icons.wifi_off_rounded,
    actionLabel: '다시 시도',
    onAction: onRetry,
  );
}
