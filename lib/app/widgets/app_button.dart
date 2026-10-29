import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading, fullWidth;
  final IconData? icon;
  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool pressed = false;
  void press(bool value) {
    if (mounted && pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final primary = widget.variant == AppButtonVariant.primary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
    );
    final content = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        if (widget.isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: '처리 중',
            ),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 21),
        Text(widget.label, textAlign: TextAlign.center),
      ],
    );
    void action() {
      HapticFeedback.selectionClick();
      widget.onPressed?.call();
    }

    final button = primary
        ? FilledButton(
            style: FilledButton.styleFrom(
              shape: shape,
              backgroundColor: enabled ? Colors.transparent : null,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 50),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: enabled ? action : null,
            child: content,
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: shape,
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size(48, 50),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: enabled ? action : null,
            child: content,
          );
    final body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        gradient: primary && enabled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C9272), AppColors.primaryDark],
              )
            : null,
        boxShadow: primary && enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .1),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: button,
    );
    return Listener(
      onPointerDown: enabled ? (_) => press(true) : null,
      onPointerUp: (_) => press(false),
      onPointerCancel: (_) => press(false),
      child: AnimatedScale(
        scale: pressed ? 0.985 : 1.0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.fullWidth
            ? SizedBox(width: double.infinity, child: body)
            : body,
      ),
    );
  }
}
