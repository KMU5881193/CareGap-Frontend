import '../../../../app/care_scope.dart';
import '../../../../core/data/live_care_repository.dart';
import '../../../live/presentation/live_auth_page.dart';

import 'package:flutter/material.dart';

import '../../../../core/models/user_role.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../app/theme/app_colors.dart';
import 'signup_page.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) =>
      CareScope.of(context).repository is LiveCareRepository
      ? const LiveAuthPage(register: true)
      : AppPage(
          title: '역할 선택',
          protected: false,
          child: PageBody(
            children: [
              const Center(child: AppBrand(size: 36)),
              const SizedBox(height: 28),
              Text(
                '어떤 역할로\n이용하시나요?',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text('선택한 역할에 맞춘 맞춤 서비스를 제공합니다.'),
              const SizedBox(height: 24),
              for (final role in UserRole.values) ...[
                AppCard(
                  color: role == UserRole.beneficiary
                      ? const Color(0xFFF1F9F2)
                      : role == UserRole.family
                      ? const Color(0xFFFFF6EF)
                      : const Color(0xFFF0F6FF),
                  onTap: () => openPage(context, SignupPage(role: role)),
                  child: Row(
                    children: [
                      PersonAvatar(
                        size: 66,
                        staff: role == UserRole.staff,
                        family: role == UserRole.family,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.label,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              role.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 10),
              AppCard(
                color: const Color(0xFFF0F3F7),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings,
                      color: Color(0xFF6C788E),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '기관 관리자',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '기관 관리자는 PC 웹에서 이용하실 수 있습니다.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: '관리자 웹 이용 안내',
                variant: AppButtonVariant.secondary,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('관리자 웹'),
                    content: const Text(
                      '기관 관리자는 별도 PC 웹을 이용합니다. 소속 기관에서 안내받은 관리자 주소로 접속해 주세요.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => openPage(context, const LoginPage()),
                child: const Text('이미 계정이 있으신가요? 로그인'),
              ),
              const Text(
                '역할은 가입 경로입니다. 실제 이용 권한은 인증된 계정과 연결 상태에 따라 결정됩니다.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
}
