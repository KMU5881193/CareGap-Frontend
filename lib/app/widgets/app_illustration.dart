import 'package:flutter/widgets.dart';

enum CareArtwork { caregiver, welfare }

/// 생성한 원본 이미지를 앱 최상위 공통 컴포넌트로 제공한다.
class CareIllustration extends StatelessWidget {
  const CareIllustration({
    super.key,
    this.height = 220,
    this.artwork = CareArtwork.caregiver,
  });
  final double height;
  final CareArtwork artwork;
  @override
  Widget build(BuildContext context) => Image.asset(
    artwork == CareArtwork.caregiver
        ? 'assets/images/care_hero_v1.png'
        : 'assets/images/welfare_home_v1.png',
    height: height,
    width: double.infinity,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
}
