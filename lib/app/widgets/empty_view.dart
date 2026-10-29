import 'package:flutter/material.dart';

import 'app_button.dart';
import '../theme/app_colors.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });
  final String title;
  final String? message, actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(message!, textAlign: TextAlign.center),
        ],
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 16),
          AppButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    ),
  );
}
