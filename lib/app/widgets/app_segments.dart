import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// 큰 글씨에서는 줄바꿈되는 브랜드 탭. 선택 상태와 터치 영역을 유지한다.
class AppSegments<T> extends StatelessWidget {
  const AppSegments({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final large =
          MediaQuery.textScalerOf(context).scale(14) > 21 ||
          constraints.maxWidth < 290;
      void choose(ButtonSegment<T> item) {
        if (!item.enabled || onSelectionChanged == null) return;
        HapticFeedback.selectionClick();
        onSelectionChanged!({item.value});
      }

      if (large) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in segments)
              ChoiceChip(
                label: item.label ?? const SizedBox.shrink(),
                selected: selected.contains(item.value),
                onSelected: !item.enabled || onSelectionChanged == null
                    ? null
                    : (_) => choose(item),
              ),
          ],
        );
      }
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F6),
          border: Border.all(color: const Color(0xFFE6EAEF)),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            for (final item in segments)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selected.contains(item.value),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: !item.enabled || onSelectionChanged == null
                          ? null
                          : () => choose(item),
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: selected.contains(item.value)
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF329B78),
                                    AppColors.primaryDark,
                                  ],
                                )
                              : null,
                        ),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected.contains(item.value)
                                ? Colors.white
                                : const Color(0xFF66718C),
                          ),
                          textAlign: TextAlign.center,
                          child: item.label ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
