import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({super.key});
  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  final form = GlobalKey<FormState>();
  final old = TextEditingController(),
      pw = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    old.dispose();
    pw.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '비밀번호 변경',
      child: PageBody(
        children: [
          const InfoPanel('안전한 이용을 위해 다른 서비스에서 사용하지 않는 비밀번호를 정해 주세요.'),
          const SizedBox(height: 24),
          Form(
            key: form,
            child: Column(
              children: [
                AppTextField(
                  label: '현재 비밀번호',
                  controller: old,
                  obscureText: true,
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? '현재 비밀번호를 입력해 주세요.' : null,
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
                  label: '새 비밀번호 확인',
                  controller: confirm,
                  obscureText: true,
                  validator: (v) => v == pw.text ? null : '비밀번호가 일치하지 않습니다.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: '비밀번호 변경',
            isLoading: busy,
            onPressed: () async {
              if (busy || !form.currentState!.validate()) return;
              setState(() => busy = true);
              final ok = await runCareTask(
                context,
                () => app.repository.changePassword(old.text, pw.text),
                success: '체험 계정 비밀번호를 변경했어요.',
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
