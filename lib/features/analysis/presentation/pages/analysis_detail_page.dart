import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../welfare/presentation/pages/welfare_detail_page.dart';
import '../../../appointments/presentation/pages/appointment_request_page.dart';
import 'analysis_review_page.dart';

class AnalysisDetailPage extends StatefulWidget {
  const AnalysisDetailPage({super.key, required this.recordId});
  final String recordId;
  @override
  State<AnalysisDetailPage> createState() => _AnalysisDetailPageState();
}

class _AnalysisDetailPageState extends State<AnalysisDetailPage> {
  bool evidence = false;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    final r = app.data?.records
        .where((r) => r.id == widget.recordId)
        .firstOrNull;
    if (r == null) {
      return const AppPage(
        title: 'AI 분석 결과',
        child: EmptyView(title: '결과에 접근할 수 없어요'),
      );
    }
    final a = r.analysis;
    return AppPage(
      title: 'AI 분석 결과',
      footer: app.isStaff && a != null && !a.approved
          ? AppButton(
              label: '상담사가 검토하기',
              icon: Icons.arrow_forward,
              onPressed: () =>
                  openPage(context, AnalysisReviewPage(recordId: r.id)),
            )
          : AppButton(
              label: app.isStaff ? '담당자 검토 완료' : '담당자에게 상담 문의',
              variant: app.isStaff
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              onPressed: app.isStaff
                  ? null
                  : () => openPage(context, const AppointmentRequestPage()),
            ),
      child: PageBody(
        children: [
          AppCard(
            color: a?.approved == true
                ? const Color(0xFFEAF6F0)
                : const Color(0xFFFFF7E9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge(
                        a == null
                            ? '분석 전'
                            : a.approved
                            ? '검토 완료'
                            : '검토 대기',
                        color: a?.approved == true
                            ? const Color(0xFF278568)
                            : const Color(0xFFAA762D),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '이 분석은 AI가 생성한 참고 초안으로, 담당자의 검토가 필요합니다.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/ai_guide_v1.png',
                  width: 105,
                  height: 105,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ],
            ),
          ),
          const SectionTitle('최근 상담 요약'),
          Text(
            '기준 상담: ${CareDate.date(r.date)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppCard(child: Text(a?.summary ?? '등록된 분석 결과가 없습니다.')),
          if (a == null && app.isStaff) ...[
            const SizedBox(height: 16),
            AsyncActionButton(
              label: '체험 분석 요청',
              action: () => app.mutate((repo) => repo.requestAnalysis(r.id)),
            ),
          ],
          if (a != null) ...[
            const SectionTitle('AI 분석 결과'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '다음 상담에서 확인할 사항',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (final q in a.questions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Color(0xFF278568),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(q)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SectionTitle('가능한 지원 방향'),
            for (final w in app.data!.welfare.take(2)) ...[
              AppCard(
                onTap: () =>
                    openPage(context, WelfareDetailPage(serviceId: w.id)),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/${w.asset}',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(w.name)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (a.notes.isNotEmpty) ...[
              const SectionTitle('추가 확인이 필요한 사항'),
              for (final n in a.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InfoPanel(n, color: const Color(0xFFAD8039)),
                ),
            ],
            const SizedBox(height: 14),
            AppButton(
              label: evidence ? '근거 접기' : '근거 보기',
              variant: AppButtonVariant.secondary,
              icon: evidence ? Icons.expand_less : Icons.expand_more,
              onPressed: () => setState(() => evidence = !evidence),
            ),
            if (evidence) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(CareDate.date(r.date)),
                    const SizedBox(height: 10),
                    SelectableText('“${a.evidence}”'),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          const InfoPanel(
            'AI 분석은 참고 자료입니다. 건강 상태의 진단이나 복지 지원 자격을 확정하지 않습니다.',
            color: Color(0xFF7884CA),
          ),
        ],
      ),
    );
  }
}
