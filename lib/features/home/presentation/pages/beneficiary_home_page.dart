import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/care_models.dart';
import '../../../appointments/presentation/pages/appointment_request_page.dart';
import '../../../appointments/presentation/pages/calendar_page.dart';
import '../../../appointments/presentation/widgets/appointment_tile.dart';
import '../../../analysis/presentation/pages/analysis_detail_page.dart';
import '../../../connections/presentation/pages/connections_page.dart';
import '../../../beneficiaries/presentation/pages/beneficiary_detail_page.dart';
import '../../../records/presentation/pages/record_detail_page.dart';
import '../../../welfare/presentation/pages/welfare_detail_page.dart';
import '../../../welfare/presentation/pages/welfare_list_page.dart';

class BeneficiaryHomePage extends StatelessWidget {
  const BeneficiaryHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), data = CareScope.of(context).data;
    if (data == null) return const SizedBox.shrink();
    final person = data.people
        .where((p) => p.id == app.selectedTargetId)
        .firstOrNull;
    final next = data.appointments
        .where(
          (a) =>
              a.start.isAfter(DateTime.now()) &&
              [
                AppointmentStatus.requested,
                AppointmentStatus.confirmed,
                AppointmentStatus.changeRequested,
              ].contains(a.status),
        )
        .firstOrNull;
    final record = data.records.firstOrNull;
    return PageBody(
      onRefresh: app.refresh,
      children: [
        Text(
          '안녕하세요,\n${app.user!.name}님! 👋',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 18),
        if (person != null)
          AppCard(
            color: const Color(0xFFF6F8FE),
            onTap: () =>
                openPage(context, BeneficiaryDetailPage(targetId: person.id)),
            child: Row(
              children: [
                const PersonAvatar(size: 70),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${person.name} 님',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        person.birthday,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        person.region,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        const SizedBox(height: 14),
        QuickGrid(
          children: [
            QuickTile(
              title: '상담 예약',
              subtitle: '일정 보기',
              icon: Icons.calendar_month,
              color: const Color(0xFF6573DA),
              onTap: () => openPage(context, const AppointmentRequestPage()),
            ),
            QuickTile(
              title: 'AI 분석 결과',
              subtitle: '생활 리포트',
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFF7789E9),
              onTap: () {
                if (record == null) {
                  toast(context, '아직 공개된 분석 결과가 없어요.');
                } else {
                  openPage(context, AnalysisDetailPage(recordId: record.id));
                }
              },
            ),
            QuickTile(
              title: '복지 서비스',
              subtitle: '맞춤 후보',
              icon: Icons.favorite_rounded,
              color: const Color(0xFFE78378),
              onTap: () =>
                  openPage(context, const WelfareListPage(standalone: true)),
            ),
            QuickTile(
              title: '가족과 연결',
              subtitle: '가족 연결 관리',
              icon: Icons.people_rounded,
              onTap: () => openPage(context, const ConnectionsPage()),
            ),
          ],
        ),
        SectionTitle(
          '다가오는 상담 일정',
          action: '전체보기 ›',
          onAction: () => openPage(
            context,
            const AppPage(title: '상담 일정', child: CalendarPage()),
          ),
        ),
        if (next != null)
          AppointmentTile(appointment: next, highlight: true)
        else
          EmptyView(
            title: '예정된 상담이 없어요',
            message: '새로운 상담 일정을 신청해 보세요.',
            actionLabel: '상담 신청',
            onAction: () => openPage(context, const AppointmentRequestPage()),
          ),
        SectionTitle(
          '추천 복지 서비스',
          action: '더보기 ›',
          onAction: () =>
              openPage(context, const WelfareListPage(standalone: true)),
        ),
        for (final service in data.welfare.take(2)) ...[
          AppCard(
            padding: const EdgeInsets.all(12),
            onTap: () =>
                openPage(context, WelfareDetailPage(serviceId: service.id)),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/${service.asset}',
                  width: 62,
                  height: 62,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (record != null) ...[
          const SectionTitle('최근 상담 결과'),
          AppCard(
            onTap: () =>
                openPage(context, RecordDetailPage(recordId: record.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '담당자가 확인한 상담 요약',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(record.summary),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
