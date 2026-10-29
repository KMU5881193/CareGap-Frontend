import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF244A36).withValues(alpha: .025),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        shape: shape,
        color: color,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : Semantics(
                button: true,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: content,
                ),
              ),
      ),
    );
  }
}
