import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';

class AccountWithdrawalPage extends StatefulWidget {
  const AccountWithdrawalPage({super.key});
  @override
  State<AccountWithdrawalPage> createState() => _AccountWithdrawalPageState();
}

class _AccountWithdrawalPageState extends State<AccountWithdrawalPage> {
  final password = TextEditingController();
  bool agreed = false, busy = false;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '회원탈퇴',
      child: PageBody(
        children: [
          const InfoPanel(
            '체험 계정의 이용과 관련 정보 접근을 중지합니다. 실제 서비스의 기록 보관·삭제 기간은 별도 정책을 따릅니다.',
            color: Color(0xFFB66A42),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: '현재 비밀번호',
            controller: password,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: agreed,
            onChanged: busy ? null : (v) => setState(() => agreed = v ?? false),
            contentPadding: EdgeInsets.zero,
            title: const Text('계정 이용과 연결된 정보 접근이 중지됨을 확인했습니다.'),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: '체험 계정 탈퇴',
            isLoading: busy,
            onPressed: !agreed
                ? null
                : () async {
                    if (busy) return;
                    final yes = await confirmCare(
                      context,
                      '회원탈퇴',
                      '체험 계정에서 탈퇴할까요?',
                    );
                    if (!yes || !mounted || !context.mounted) return;
                    setState(() => busy = true);
                    final ok = await runCareTask(context, () async {
                      await app.repository.withdraw(password.text);
                      await app.signOut();
                    });
                    if (!mounted || !context.mounted) return;
                    setState(() => busy = false);
                    if (ok) Navigator.of(context).popUntil((r) => r.isFirst);
                  },
          ),
        ],
      ),
    );
  }
}
