import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/models/frontend_models.dart';
import '../../../../core/media/media_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.role});
  final UserRole role;
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      id = TextEditingController(),
      phone = TextEditingController(),
      pw = TextEditingController(),
      again = TextEditingController(),
      agency = TextEditingController(),
      relation = TextEditingController();
  MediaInput? certificate;
  DateTime? birth;
  bool agreed = false, busy = false;
  @override
  void dispose() {
    for (final c in [name, id, phone, pw, again, agency, relation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickCertificate() async {
    await runCareTask(context, () async {
      final f = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: '자격 자료',
            extensions: ['jpg', 'jpeg', 'png', 'pdf'],
            mimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
            uniformTypeIdentifiers: [
              'public.jpeg',
              'public.png',
              'com.adobe.pdf',
            ],
          ),
        ],
      );
      if (f == null) return;
      final input = await MediaSelectionService.instance.readFile(
        f,
        'qualification',
      );
      if (mounted) setState(() => certificate = input);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '${widget.role.label} 회원가입',
      protected: false,
      child: PageBody(
        children: [
          Center(
            child: PersonAvatar(
              size: 76,
              staff: widget.role == UserRole.staff,
              family: widget.role == UserRole.family,
            ),
          ),
          const SizedBox(height: 20),
          const InfoPanel(
            '체험 가입에는 가상 정보를 입력해 주세요. 실제 본인 확인이나 자격 심사를 대신하지 않습니다.',
          ),
          const SizedBox(height: 24),
          Form(
            key: form,
            child: Column(
              children: [
                AppTextField(
                  label: '이름',
                  controller: name,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? '이름을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: '연락처',
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      RegExp(r'^01[0-9]{8,9}$')
                          .hasMatch((v ?? '').replaceAll('-', ''))
                      ? null
                      : '연락처를 확인해 주세요.',
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: '아이디',
                  controller: id,
                  validator: (v) =>
                      RegExp(r'^[a-zA-Z0-9_]{4,24}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : '영문·숫자·밑줄 4~24자로 입력해 주세요.',
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: '비밀번호',
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
                if (widget.role == UserRole.beneficiary) ...[
                  const SizedBox(height: 20),
                  AppButton(
                    label: birth == null
                        ? '생년월일 선택'
                        : '${birth!.year}-${birth!.month}-${birth!.day}',
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      final d = await pickCareDate(
                        context,
                        birth ?? DateTime(1950, 1, 1),
                      );
                      if (d != null && mounted) setState(() => birth = d);
                    },
                  ),
                ],
                if (widget.role == UserRole.family) ...[
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '대상자와의 관계',
                    controller: relation,
                    hintText: '예: 자녀',
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? '관계를 입력해 주세요.' : null,
                  ),
                ],
                if (widget.role == UserRole.staff) ...[
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '소속 기관',
                    controller: agency,
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? '소속 기관을 입력해 주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: certificate?.name ?? '자격 자료 선택',
                    icon: Icons.upload_file_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: busy ? null : pickCertificate,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: agreed,
            onChanged: busy ? null : (v) => setState(() => agreed = v ?? false),
            title: const Text('예시 정보로 체험 가입합니다'),
          ),
          AppButton(
            label: '체험 계정 만들기',
            isLoading: busy,
            onPressed: !agreed
                ? null
                : () async {
                    if (busy || !form.currentState!.validate()) return;
                    if (widget.role == UserRole.staff && certificate == null) {
                      toast(context, '시험용 자격 자료를 선택해 주세요.');
                      return;
                    }
                    if (widget.role == UserRole.beneficiary &&
                        (birth == null || birth!.isAfter(DateTime.now()))) {
                      toast(context, '올바른 생년월일을 선택해 주세요.');
                      return;
                    }
                    setState(() => busy = true);
                    final ok = await runCareTask(context, () async {
                      await app.register(
                        name.text,
                        id.text,
                        pw.text,
                        widget.role,
                      );
                      await app.repository.updateProfile(
                        ProfileData(
                          name: name.text,
                          phone: phone.text,
                          birthday: birth == null
                              ? ''
                              : '${birth!.year}-${birth!.month}-${birth!.day}',
                          agency: agency.text,
                          relation: relation.text,
                        ),
                      );
                      if (certificate != null) {
                        await app.repository.submitQualification(certificate!);
                      }
                      await app.refresh();
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

class StaffResubmissionPage extends StatefulWidget {
  const StaffResubmissionPage({super.key});
  @override
  State<StaffResubmissionPage> createState() => _StaffResubmissionPageState();
}

class _StaffResubmissionPageState extends State<StaffResubmissionPage> {
  MediaInput? file;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '자격 자료 재제출',
      protected: false,
      child: PageBody(
        children: [
          const InfoPanel(
            '체험용 자료만 선택해 주세요. 실제 서버에 전송하지 않으며 심사 상태만 승인 대기로 변경합니다.',
          ),
          const SizedBox(height: 24),
          AppButton(
            label: file?.name ?? '자격 자료 선택',
            variant: AppButtonVariant.secondary,
            onPressed: () => runCareTask(context, () async {
              final f = await openFile(
                acceptedTypeGroups: const [
                  XTypeGroup(
                    label: '자료',
                    extensions: ['pdf', 'png', 'jpg'],
                    uniformTypeIdentifiers: ['public.image', 'com.adobe.pdf'],
                  ),
                ],
              );
              if (f != null) {
                final data = await MediaSelectionService.instance.readFile(
                  f,
                  'qualification',
                );
                if (mounted) setState(() => file = data);
              }
            }),
          ),
          const SizedBox(height: 20),
          if (file != null)
            AsyncActionButton(
              label: '자료 재제출',
              action: () async {
                await app.repository.submitQualification(file!);
                await app.refresh();
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
