import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';

class AnalysisReviewPage extends StatefulWidget {
  const AnalysisReviewPage({super.key, required this.recordId});
  final String recordId;
  @override
  State<AnalysisReviewPage> createState() => _AnalysisReviewPageState();
}

class _AnalysisReviewPageState extends State<AnalysisReviewPage> {
  final text = TextEditingController();
  String? original;
  bool init = false, busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (init) return;
    final r = CareScope.of(context).data?.records
        .where((r) => r.id == widget.recordId)
        .firstOrNull;
    if (r != null) {
      text.text = r.analysis?.summary ?? '';
      original = r.original;
      init = true;
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    final r = app.data?.records
        .where((r) => r.id == widget.recordId)
        .firstOrNull;
    if (!app.isStaff || r == null || r.analysis == null) {
      return const AppPage(
        title: '분석 검토',
        child: EmptyView(title: '검토할 결과에 접근할 수 없어요'),
      );
    }
    return AppPage(
      title: 'AI 분석 검토',
      child: PageBody(
        children: [
          const InfoPanel(
            '원문 근거를 확인하고 요약을 수정한 뒤 승인해 주세요. 검토 승인과 대상자 공개는 별도입니다.',
          ),
          const SectionTitle('상담 원문'),
          AppCard(child: SelectableText(r.original)),
          const SectionTitle('분석 요약 수정'),
          AppTextField(label: '검토한 요약', controller: text, maxLines: 8),
          const SizedBox(height: 24),
          AppButton(
            label: '검토 완료',
            isLoading: busy,
            onPressed: () async {
              if (busy || text.text.trim().isEmpty) return;
              if (r.original != original) {
                toast(context, '원문이 변경되었습니다. 화면을 다시 열어 주세요.');
                return;
              }
              if (!await confirmCare(
                context,
                '검토 완료',
                '검토를 완료할까요? 새 기록은 이 작업만으로 자동 공개되지 않습니다.',
              )) {
                return;
              }
              if (!mounted || !context.mounted) return;
              setState(() => busy = true);
              final ok = await runCareTask(
                context,
                () =>
                    app.mutate((repo) => repo.approveAnalysis(r.id, text.text)),
                success: '분석 검토를 완료했어요.',
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
