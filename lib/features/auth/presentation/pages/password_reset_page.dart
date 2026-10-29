import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});
  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final form = GlobalKey<FormState>();
  final id = TextEditingController(),
      code = TextEditingController(),
      pw = TextEditingController(),
      again = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    for (final c in [id, code, pw, again]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '비밀번호 재설정',
      protected: false,
      child: PageBody(
        children: [
          const InfoPanel(
            '체험 확인 코드는 123456입니다. 실제 서비스에서는 본인 확인 후 발급받은 코드가 필요합니다.',
          ),
          const SizedBox(height: 24),
          Form(
            key: form,
            child: Column(
              children: [
                AppTextField(
                  label: '아이디',
                  controller: id,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? '아이디를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: '확인 코드',
                  controller: code,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v?.length ?? 0) == 6 ? null : '6자리 코드를 입력해 주세요.',
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: '새 비밀번호',
                  controller: pw,
                  obscureText: true,
                  validator: (v) =>
                      (v?.length ?? 0) >= 8 ? null : '8자 이상 입력해 주세요.',
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: '비밀번호 확인',
                  controller: again,
                  obscureText: true,
                  validator: (v) => v == pw.text ? null : '비밀번호가 일치하지 않습니다.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: '재설정',
            isLoading: busy,
            onPressed: () async {
              if (busy || !form.currentState!.validate()) return;
              setState(() => busy = true);
              final ok = await runCareTask(
                context,
                () => app.repository.resetPassword(
                  id.text.trim(),
                  code.text.trim(),
                  pw.text,
                ),
                success: '체험 계정의 비밀번호를 재설정했어요.',
              );
              if (!mounted || !context.mounted) return;
              setState(() => busy = false);
              if (ok) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
