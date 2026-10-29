import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/care_models.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../appointments/presentation/widgets/appointment_tile.dart';
import '../../../appointments/presentation/pages/calendar_page.dart';
import '../../../appointments/presentation/pages/availability_page.dart';
import '../../../beneficiaries/presentation/pages/beneficiaries_page.dart';
import '../../../followups/presentation/pages/followups_page.dart';
import '../../../analysis/presentation/pages/analysis_detail_page.dart';
import '../../../records/presentation/pages/record_editor_page.dart';

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), data = CareScope.of(context).data;
    if (data == null) return const SizedBox.shrink();
    final today = data.appointments
        .where((a) => CareDate.sameDay(a.start, DateTime.now()))
        .toList();
    final requests = data.appointments
        .where(
          (a) => [
            AppointmentStatus.requested,
            AppointmentStatus.changeRequested,
          ].contains(a.status),
        )
        .toList();
    final reviews = data.records
        .where((r) => r.analysis != null && !r.analysis!.approved)
        .toList();
    return PageBody(
      onRefresh: app.refresh,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘의 업무', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(CareDate.date(DateTime.now())),
                ],
              ),
            ),
            const PersonAvatar(staff: true, size: 50),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          color: const Color(0xFFEAF6F0),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 14,
            runSpacing: 14,
            children: [
              _Metric('오늘 상담', today.length, Icons.schedule),
              _Metric('대기 요청', requests.length, Icons.receipt_long_outlined),
              _Metric('AI 검토 대기', reviews.length, Icons.auto_awesome_outlined),
            ],
          ),
        ),
        SectionTitle(
          '오늘의 상담 일정',
          action: '캘린더 보기',
          onAction: () => openPage(
            context,
            const AppPage(title: '상담 일정', child: CalendarPage()),
          ),
        ),
        if (today.isEmpty) const EmptyView(title: '오늘 예정된 상담이 없어요'),
        for (final a in today) ...[
          AppointmentTile(appointment: a),
          const SizedBox(height: 12),
        ],
        const SectionTitle('확인할 업무'),
        QuickGrid(
          children: [
            QuickTile(
              title: '상담 요청 대기',
              subtitle: '${requests.length}건',
              icon: Icons.mark_chat_unread_outlined,
              color: const Color(0xFFCC8B63),
              onTap: () => openPage(
                context,
                const AppPage(title: '상담 요청', child: CalendarPage()),
              ),
            ),
            QuickTile(
              title: 'AI 검토 대기',
              subtitle: '${reviews.length}건',
              icon: Icons.auto_awesome_outlined,
              color: const Color(0xFF8D7ECB),
              onTap: () {
                if (reviews.isEmpty) {
                  toast(context, '검토 대기 중인 결과가 없어요.');
                } else {
                  openPage(
                    context,
                    AnalysisDetailPage(recordId: reviews.first.id),
                  );
                }
              },
            ),
            QuickTile(
              title: '담당 대상자',
              subtitle: '${data.people.length}명',
              icon: Icons.people_outline,
              onTap: () => openPage(context, const BeneficiariesPage()),
            ),
            QuickTile(
              title: '후속 확인',
              subtitle: '${data.followups.where((f) => !f.done).length}건',
              icon: Icons.checklist,
              onTap: () => openPage(context, const FollowupsPage()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppButton(
          label: '상담 기록 작성',
          icon: Icons.add,
          onPressed: () => openPage(context, const RecordEditorPage()),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: '상담 가능 시간 설정',
          variant: AppButtonVariant.secondary,
          onPressed: () => openPage(context, const AvailabilityPage()),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 22, color: const Color(0xFF278568)),
      const SizedBox(height: 7),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 5),
      Text('$value건', style: Theme.of(context).textTheme.titleSmall),
    ],
  );
}
