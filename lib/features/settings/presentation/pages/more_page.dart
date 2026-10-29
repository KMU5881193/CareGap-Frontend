import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../connections/presentation/pages/connections_page.dart';
import '../../../beneficiaries/presentation/pages/beneficiaries_page.dart';
import '../../../followups/presentation/pages/followups_page.dart';
import '../../../appointments/presentation/pages/availability_page.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../counseling/presentation/pages/counseling_entry_page.dart';
import 'accessibility_page.dart';
import 'profile_page.dart';
import 'password_change_page.dart';
import 'account_withdrawal_page.dart';
import 'help_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), user = CareScope.of(context).user!;
    Widget menu(String title, String sub, IconData icon, Widget page) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onTap: () => openPage(context, page),
            child: Row(
              children: [
                IconBubble(icon, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(sub, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        );
    return PageBody(
      children: [
        AppCard(
          onTap: () => openPage(context, const ProfilePage()),
          child: Row(
            children: [
              PersonAvatar(size: 70, staff: app.isStaff),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.name}님',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${user.role.label} · 케어노트와 함께\n오늘도 좋은 하루 보내세요! 🌿',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 20),
        menu(
          '계정 정보',
          '이름과 연락처 등 기본 정보를 관리합니다.',
          Icons.person,
          const ProfilePage(),
        ),
        menu(
          '접근성 설정',
          '글자 크기와 높은 대비를 설정합니다.',
          Icons.accessibility_new,
          const AccessibilityPage(),
        ),
        menu(
          '알림 설정',
          '상담·일정 알림 설정을 관리합니다.',
          Icons.notifications_none,
          const NotificationSettingsPage(),
        ),
        menu(
          '가족 연결 관리',
          '연결된 가족을 확인하고 관리합니다.',
          Icons.people_outline,
          const ConnectionsPage(),
        ),
        menu(
          '비밀번호 변경',
          '안전한 이용을 위해 비밀번호를 변경합니다.',
          Icons.lock_outline,
          const PasswordChangePage(),
        ),
        if (app.isStaff) ...[
          menu(
            '담당 대상자',
            '담당하는 대상자의 상담 이력을 확인합니다.',
            Icons.badge_outlined,
            const BeneficiariesPage(),
          ),
          menu(
            '상담 가능 시간',
            '가능 요일과 휴가 날짜를 설정합니다.',
            Icons.schedule,
            const AvailabilityPage(),
          ),
          menu(
            '후속 확인',
            '상담 후 확인할 일을 관리합니다.',
            Icons.checklist,
            const FollowupsPage(),
          ),
        ],
        menu(
          '도움말 / 고객센터',
          '자주 묻는 질문과 이용 안내를 확인합니다.',
          Icons.help_outline,
          const HelpPage(),
        ),
        menu(
          '후속 기능 미리보기',
          '전화·영상·채팅 화면을 확인합니다.',
          Icons.video_chat_outlined,
          const CounselingEntryPage(),
        ),
        menu(
          '오픈소스 라이선스',
          '앱이 사용하는 오픈소스를 확인합니다.',
          Icons.description_outlined,
          const LicensePage(applicationName: '케어노트'),
        ),
        const SizedBox(height: 8),
        AsyncActionButton(
          label: '로그아웃',
          secondary: true,
          action: () async {
            if (await confirmCare(context, '로그아웃', '현재 계정에서 로그아웃할까요?')) {
              await app.signOut();
            }
          },
        ),
        TextButton(
          onPressed: () => openPage(context, const AccountWithdrawalPage()),
          child: const Text('회원탈퇴', style: TextStyle(color: Color(0xFFB66A6A))),
        ),
      ],
    );
  }
}
