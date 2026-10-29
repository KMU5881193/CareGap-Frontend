import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/notifications/push_service.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final push = PushService.instance;
    return AnimatedBuilder(
      animation: push,
      builder: (context, _) => AppPage(
        title: '알림 설정',
        child: PageBody(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: IconBubble(
                      Icons.notifications_active_outlined,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '필요한 순간에 전하는 돌봄 소식',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('알림을 허용하면 이 기기에서 돌봄 소식을 받아볼 수 있어요.'),
                  const SizedBox(height: 16),
                  Text(
                    push.status,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('이 기기의 푸시 알림'),
                    subtitle: const Text('기기 알림 권한과 FCM 등록을 관리해요'),
                    value: push.enabled,
                    onChanged: push.configured && !push.busy
                        ? (value) => push.setEnabled(value)
                        : null,
                  ),
                  if (push.busy) const LinearProgressIndicator(),
                  if (push.error != null) ...[
                    const SizedBox(height: 12),
                    InfoPanel(push.error!),
                  ],
                  const SizedBox(height: 12),
                  AppButton(
                    label: '연결 상태 다시 확인',
                    variant: AppButtonVariant.secondary,
                    onPressed: push.configured && !push.busy
                        ? push.refresh
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!push.configured)
              const InfoPanel(
                'Firebase 프로젝트 등록이 필요해요. 프로젝트 연결과 앱 재실행 후 알림을 허용할 수 있어요.',
              ),
            const SizedBox(height: 12),
            const InfoPanel(
              '기기 설정에서 알림을 거부했다면 iPhone 설정 → 알림 또는 Android 설정 → 앱 → 케어노트 → 알림에서 허용해 주세요.',
            ),
            const SizedBox(height: 20),
            const SectionTitle('받고 싶은 소식'),
            const SizedBox(height: 8),
            const Text(
              '아래 선택은 기존 체험 설정입니다. 예약·상담 결과의 실제 자동 발송은 백엔드 연결 후 적용됩니다.',
            ),
            for (final entry in CareScope.of(
              context,
            ).notificationPreferences.entries)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key),
                value: entry.value,
                onChanged: (value) =>
                    CareScope.of(context).setPreference(entry.key, value),
              ),
            const SizedBox(height: 20),
            const InfoPanel(
              '잠금 화면에는 상담 원문과 분석 내용을 넣지 않는 발송 계약을 사용합니다. 현재 서버 알림함과는 연결되지 않았으며, 알림을 누르면 로그인 후 이 설정 화면을 엽니다.',
            ),
            if (push.tokenForTesting != null) ...[
              const SizedBox(height: 24),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('개발용 알림 테스트'),
                children: [
                  const Text(
                    'Firebase 콘솔의 테스트 메시지에 사용할 기기 토큰입니다. 토큰은 화면이나 로그에 표시하지 않습니다.',
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: '테스트용 FCM 토큰 복사',
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      final token = push.tokenForTesting;
                      if (token == null) return;
                      await Clipboard.setData(ClipboardData(text: token));
                      if (context.mounted) toast(context, '테스트용 기기 토큰을 복사했어요.');
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
