import '../../../../core/data/live_care_repository.dart';
import '../../../live/presentation/live_auth_page.dart';

import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import 'role_selection_page.dart';
import 'account_recovery_page.dart';
import 'password_reset_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final id = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false, hidden = true;
  @override
  void dispose() {
    id.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    final controller = CareScope.of(context);
    final ok = await runCareTask(
      context,
      () => controller.signIn(id.text, password.text),
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) =>
      CareScope.of(context).repository is LiveCareRepository
      ? const LiveAuthPage()
      : AppPage(
          title: '로그인',
          protected: false,
          child: PageBody(
            children: [
              Text('다시 만나 반가워요', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text('아래 체험 계정을 선택하면 입력란이 채워집니다.'),
              const SizedBox(height: 24),
              Form(
                key: form,
                child: AutofillGroup(
                  child: Column(
                    children: [
                      AppTextField(
                        label: '아이디',
                        controller: id,
                        enabled: !busy,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? '아이디를 입력해 주세요.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: '비밀번호',
                        controller: password,
                        enabled: !busy,
                        obscureText: hidden,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => login(),
                        validator: (v) =>
                            (v?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                        suffixIcon: IconButton(
                          tooltip: hidden ? '비밀번호 보기' : '비밀번호 숨기기',
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(label: '로그인', onPressed: login, isLoading: busy),
              TextButton(
                onPressed: busy
                    ? null
                    : () => openPage(context, const RoleSelectionPage()),
                child: const Text('새 계정으로 시작하기'),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () =>
                        openPage(context, const AccountRecoveryPage()),
                    child: const Text('아이디 찾기'),
                  ),
                  TextButton(
                    onPressed: () =>
                        openPage(context, const PasswordResetPage()),
                    child: const Text('비밀번호 재설정'),
                  ),
                ],
              ),
              const SectionTitle('화면 확인용 체험 계정'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in const {
                    '대상자': 'beneficiary',
                    '연결된 가족': 'family',
                    '미연결 가족': 'family_pending',
                    '담당자': 'staff',
                    '승인 대기': 'staff_pending',
                    '반려 담당자': 'staff_rejected',
                  }.entries)
                    ActionChip(
                      label: Text(entry.key),
                      onPressed: busy
                          ? null
                          : () {
                              id.text = entry.value;
                              password.text = 'care1234';
                            },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const InfoPanel('공통 비밀번호: care1234\n체험 계정에는 실제 개인정보를 입력하지 마세요.'),
            ],
          ),
        );
}
