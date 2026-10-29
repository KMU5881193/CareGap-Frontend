import 'package:flutter/material.dart';

import '../../../../app/widgets/app_widgets.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBrand(size: 44),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('돌봄 정보를 확인하고 있어요'),
          ],
        ),
      ),
    ),
  );
}
