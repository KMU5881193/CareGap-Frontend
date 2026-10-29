import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBrand extends StatelessWidget {
  const AppBrand({super.key, this.size = 30, this.compact = false});
  final double size;
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/images/brand_mark_v1.png',
        width: size,
        height: size,
        excludeFromSemantics: true,
      ),
      if (!compact) ...[
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            '돌봄틈새 AI',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: size * .65,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
        ),
      ],
    ],
  );
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    this.size = 56,
    this.staff = false,
    this.family = false,
  });
  final double size;
  final bool staff, family;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: staff ? const Color(0xFFE9F1FC) : const Color(0xFFF0ECF7),
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset(
      'assets/images/${family
          ? 'family_care_v1.png'
          : staff
          ? 'staff_avatar_v1.png'
          : 'elder_avatar_v1.png'}',
      fit: family ? BoxFit.cover : BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}

class SoftBanner extends StatelessWidget {
  const SoftBanner({
    super.key,
    required this.title,
    required this.message,
    this.asset = 'care_hero_v1.png',
    this.color = const Color(0xFFEAF5EF),
    this.height = 170,
  });
  final String title, message, asset;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final large = MediaQuery.textScalerOf(context).scale(16) > 24;
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
        final art = Image.asset(
          'assets/images/$asset',
          width: large ? double.infinity : 120,
          height: large ? 130 : height - 36,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        );
        return large
            ? Column(children: [text, art])
            : Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 8),
                  art,
                ],
              );
      },
    ),
  );
}
