import 'package:flutter/material.dart';

import '../../../app/care_scope.dart';
import '../../../app/widgets/app_widgets.dart';
import '../../../core/models/user_role.dart';
import '../../../core/data/live_care_repository.dart';

class LiveAuthPage extends StatefulWidget {
  const LiveAuthPage({super.key, this.register = false});
  final bool register;
  @override
  State<LiveAuthPage> createState() => _LiveAuthPageState();
}

class _LiveAuthPageState extends State<LiveAuthPage> {
  final id = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool consent = false, busy = false, hidden = true;
  @override
  void dispose() {
    id.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: widget.register ? '합성 담당자 계정 만들기' : '담당자 로그인',
    protected: false,
    child: PageBody(
      children: [
        const Center(child: AppBrand(size: 40)),
        const SizedBox(height: 24),
        Text(
          widget.register ? '돌봄을 연결하는 첫걸음' : '다시 만나 반가워요',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        const InfoPanel(
          '현재 서버는 합성 시연용 담당자만 지원합니다. 실제 개인정보를 입력하지 마세요. 서버 재시작 시 계정과 기록이 초기화됩니다.',
        ),
        const SizedBox(height: 24),
        SelectableText(
          '연결 주소: ${(CareScope.of(context).repository as LiveCareRepository).api.base.origin}',
        ),
        Form(
          key: form,
          child: Column(
            children: [
              AppTextField(
                label: '아이디 (3~80자)',
                controller: id,
                enabled: !busy,
                validator: (v) =>
                    (v?.trim().length ?? 0) >= 3 &&
                        (v?.trim().length ?? 0) <= 80
                    ? null
                    : '3~80자로 입력해 주세요.',
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: '비밀번호 (12~128자)',
                controller: password,
                enabled: !busy,
                obscureText: hidden,
                suffixIcon: IconButton(
                  tooltip: '비밀번호 표시 전환',
                  onPressed: () => setState(() => hidden = !hidden),
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (v) =>
                    (v?.length ?? 0) >= 12 && (v?.length ?? 0) <= 128
                    ? null
                    : '12~128자로 입력해 주세요.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (widget.register)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: busy
                ? null
                : (v) => setState(() => consent = v ?? false),
            title: const Text('가상 계정과 합성 상담 데이터만 사용합니다.'),
          ),
        AppButton(
          label: widget.register ? '계정 생성 후 로그인' : '로그인',
          isLoading: busy,
          onPressed: widget.register && !consent
              ? null
              : () async {
                  if (busy || !form.currentState!.validate()) return;
                  setState(() => busy = true);
                  final app = CareScope.of(context);
                  final ok = await runCareTask(
                    context,
                    () => widget.register
                        ? app.register(
                            '',
                            id.text,
                            password.text,
                            UserRole.staff,
                          )
                        : app.signIn(id.text, password.text),
                  );
                  if (!mounted || !context.mounted) return;
                  setState(() => busy = false);
                  if (ok) Navigator.of(context).popUntil((r) => r.isFirst);
                },
        ),
        TextButton(
          onPressed: busy
              ? null
              : () =>
                    openPage(context, LiveAuthPage(register: !widget.register)),
          child: Text(widget.register ? '이미 계정이 있어요' : '새 합성 담당자 계정 만들기'),
        ),
      ],
    ),
  );
}
