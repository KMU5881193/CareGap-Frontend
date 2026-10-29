import 'package:flutter/material.dart';

import '../../../../app/widgets/app_widgets.dart';
import '../../../../app/theme/app_colors.dart';
import 'role_selection_page.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const DemoBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Image.asset(
                          'assets/images/brand_mark_v1.png',
                          width: 76,
                          height: 76,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '돌봄틈새 AI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                '언제나,\n곁에 있는 돌봄 파트너',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(height: 1.35),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('상담부터 복지정보까지,\n더 스마트한 돌봄을 시작해요.'),
                          ],
                        ),
                      ),
                      const CareIllustration(height: 255),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          '놓치기 쉬운 돌봄의 틈,\nAI가 함께합니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.6,
                            color: AppColors.primaryDark,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle, size: 8, color: AppColors.primary),
                          SizedBox(width: 10),
                          Icon(Icons.circle, size: 8, color: Color(0xFFCDD6D1)),
                          SizedBox(width: 10),
                          Icon(Icons.circle, size: 8, color: Color(0xFFCDD6D1)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Column(
                          children: [
                            AppButton(
                              label: '시작하기',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: () =>
                                  openPage(context, const RoleSelectionPage()),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () =>
                                  openPage(context, const LoginPage()),
                              child: const Text('로그인'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
