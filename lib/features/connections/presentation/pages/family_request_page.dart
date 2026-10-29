import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/user_role.dart';

class FamilyRequestPage extends StatefulWidget {
  const FamilyRequestPage({super.key});
  @override
  State<FamilyRequestPage> createState() => _FamilyRequestPageState();
}

class _FamilyRequestPageState extends State<FamilyRequestPage> {
  final code = TextEditingController();
  bool agreed = false, busy = false, done = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '가족 연결 요청',
      protected: false,
      child: PageBody(
        children: [
          Image.asset(
            'assets/images/family_care_v1.png',
            height: 200,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          Text(
            '소중한 가족과 함께\n돌봄을 이어가세요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          const InfoPanel(
            '대상자가 직접 허용한 뒤에만 상담 정보에 접근할 수 있습니다. 연결 해제 후에는 접근이 차단됩니다.',
          ),
          const SizedBox(height: 20),
          if (app.user?.role == UserRole.family) ...[
            AppTextField(
              label: '체험 연결 코드',
              controller: code,
              hintText: 'DEMO123',
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: agreed,
              onChanged: (v) => setState(() => agreed = v ?? false),
              title: const Text('대상자의 동의와 가족 관계 확인이 필요함을 확인했습니다.'),
            ),
            const SizedBox(height: 16),
            if (done)
              const InfoPanel('연결 요청을 보냈어요. 대상자의 허용을 기다려 주세요.')
            else
              AppButton(
                label: '가족 연결 요청하기',
                isLoading: busy,
                onPressed: !agreed
                    ? null
                    : () async {
                        if (busy) return;
                        setState(() => busy = true);
                        final ok = await runCareTask(
                          context,
                          () => app.repository.requestFamilyLink(
                            code.text.trim(),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            done = ok;
                            busy = false;
                          });
                        }
                      },
              ),
          ] else
            const AppCard(
              child: Text(
                '가족은 가족 계정으로 로그인해 연결을 요청할 수 있습니다. 대상자 본인은 연결 관리에서 요청을 허용하거나 해제합니다.',
              ),
            ),
        ],
      ),
    );
  }
}
