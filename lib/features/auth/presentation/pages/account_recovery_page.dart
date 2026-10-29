import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import 'password_reset_page.dart';

class AccountRecoveryPage extends StatefulWidget {
  const AccountRecoveryPage({super.key});
  @override
  State<AccountRecoveryPage> createState() => _AccountRecoveryPageState();
}

class _AccountRecoveryPageState extends State<AccountRecoveryPage> {
  final phone = TextEditingController();
  String? result;
  bool busy = false;
  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '아이디 찾기',
      protected: false,
      child: PageBody(
        children: [
          const InfoPanel(
            '체험 연락처 01000000000으로 확인할 수 있습니다. 실제 본인 확인이나 문자 발송은 진행하지 않습니다.',
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: '가입 연락처',
            controller: phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: '아이디 확인',
            isLoading: busy,
            onPressed: () async {
              if (busy) return;
              setState(() => busy = true);
              await runCareTask(context, () async {
                final id = await app.repository.recoverAccount(phone.text);
                if (mounted) setState(() => result = id);
              });
              if (mounted) setState(() => busy = false);
            },
          ),
          if (result != null) ...[
            const SizedBox(height: 20),
            AppCard(child: Text('체험 아이디: $result')),
            const SizedBox(height: 12),
            AppButton(
              label: '비밀번호 재설정',
              variant: AppButtonVariant.secondary,
              onPressed: () => openPage(context, const PasswordResetPage()),
            ),
          ],
        ],
      ),
    );
  }
}
