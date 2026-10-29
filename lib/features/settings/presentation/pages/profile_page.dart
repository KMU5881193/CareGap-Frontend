import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/frontend_models.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      phone = TextEditingController(),
      birth = TextEditingController(),
      agency = TextEditingController();
  bool started = false, busy = false, ready = false;
  String? error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      load();
    }
  }

  Future<void> load() async {
    try {
      final p = await CareScope.of(context).repository.profile();
      if (!mounted) return;
      setState(() {
        name.text = p.name;
        phone.text = p.phone;
        birth.text = p.birthday;
        agency.text = p.agency;
        ready = true;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  void dispose() {
    for (final c in [name, phone, birth, agency]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '계정 정보',
      child: PageBody(
        children: [
          Center(child: PersonAvatar(size: 84, staff: app.isStaff)),
          const SizedBox(height: 20),
          if (error != null)
            ErrorView(message: error!, onRetry: load)
          else if (!ready)
            const LoadingView()
          else
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
                    label: '생년월일 (선택)',
                    controller: birth,
                    hintText: 'YYYY-MM-DD',
                  ),
                  if (app.isStaff) ...[
                    const SizedBox(height: 20),
                    AppTextField(label: '소속 기관', controller: agency),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    label: '정보 저장',
                    isLoading: busy,
                    onPressed: () async {
                      if (busy || !form.currentState!.validate()) return;
                      setState(() => busy = true);
                      await runCareTask(context, () async {
                        await app.repository.updateProfile(
                          ProfileData(
                            name: name.text,
                            phone: phone.text,
                            birthday: birth.text,
                            agency: agency.text,
                          ),
                        );
                        await app.refresh();
                      }, success: '계정 정보를 저장했어요.');
                      if (mounted) setState(() => busy = false);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
