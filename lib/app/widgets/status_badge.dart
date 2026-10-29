import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    super.key,
    this.color = AppColors.primaryDark,
  });
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}
