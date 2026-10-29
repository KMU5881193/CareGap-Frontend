import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../core/models/care_models.dart';
import '../../../../core/models/user_role.dart';
import '../../../auth/presentation/pages/signup_page.dart';
import '../../../../app/widgets/app_widgets.dart';

class AccessRestrictedPage extends StatefulWidget {
  const AccessRestrictedPage({super.key});
  @override
  State<AccessRestrictedPage> createState() => _AccessRestrictedPageState();
}

class _AccessRestrictedPageState extends State<AccessRestrictedPage> {
  final code = TextEditingController();
  bool requested = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), user = CareScope.of(context).user!;
    final family = user.role == UserRole.family;
    return AppPage(
      title: family ? '가족 연결' : '담당자 심사 상태',
      protected: false,
      child: PageBody(
        children: [
          const SizedBox(height: 32),
          Icon(
            family ? Icons.family_restroom : Icons.verified_user_outlined,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            family
                ? '대상자의 연결 허용이 필요해요'
                : user.approval == Approval.rejected
                ? '제출 자료를 다시 확인해 주세요'
                : '담당자 승인을 기다리고 있어요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            family
                ? '대상자가 연결을 허용한 뒤 상담 정보를 볼 수 있습니다.'
                : user.reason ?? '심사 완료 전에는 상담 업무를 이용할 수 없습니다.',
          ),
          if (family) ...[
            const SizedBox(height: 24),
            AppTextField(
              label: '체험 연결 코드',
              controller: code,
              hintText: 'DEMO123',
            ),
            const SizedBox(height: 16),
            if (requested)
              const InfoPanel('연결 요청을 보냈어요. 대상자의 허용을 기다려 주세요.')
            else
              AsyncActionButton(
                label: '연결 요청',
                action: () async {
                  await app.repository.requestFamilyLink(code.text.trim());
                  if (mounted) setState(() => requested = true);
                },
              ),
          ],
          const SizedBox(height: 24),
          if (!family)
            AppButton(
              label: '자격 자료 재제출',
              variant: AppButtonVariant.secondary,
              onPressed: () => openPage(context, const StaffResubmissionPage()),
            ),
          const SizedBox(height: 12),
          AsyncActionButton(
            label: '상태 새로고침',
            secondary: true,
            action: app.refresh,
          ),
          const SizedBox(height: 12),
          AsyncActionButton(
            label: '로그아웃',
            secondary: true,
            action: app.signOut,
          ),
        ],
      ),
    );
  }
}
