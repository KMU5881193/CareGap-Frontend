import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/utils/date_formatter.dart';

class CumulativeAnalysisPage extends StatefulWidget {
  const CumulativeAnalysisPage({super.key});
  @override
  State<CumulativeAnalysisPage> createState() => _CumulativeAnalysisPageState();
}

class _CumulativeAnalysisPageState extends State<CumulativeAnalysisPage> {
  int months = 3;
  Set<String> selected = {};
  bool result = false;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    if (!app.isStaff) {
      return const AppPage(
        title: '누적 상담 분석',
        child: EmptyView(title: '담당자만 이용할 수 있어요'),
      );
    }
    final list = (app.data?.records ?? [])
        .where(
          (r) =>
              months == 0 ||
              r.date.isAfter(
                DateTime.now().subtract(Duration(days: months * 31)),
              ),
        )
        .toList();
    return AppPage(
      title: '누적 상담 분석',
      child: PageBody(
        children: [
          const SoftBanner(
            title: '상담의 흐름을 함께 확인해요',
            message: '포함할 기간과 기록을 선택하세요.',
            asset: 'ai_guide_v1.png',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              for (final m in [1, 3, 0])
                ChoiceChip(
                  label: Text(m == 0 ? '전체' : '최근 $m개월'),
                  selected: months == m,
                  onSelected: (_) => setState(() {
                    months = m;
                    result = false;
                  }),
                ),
            ],
          ),
          const SectionTitle('분석 대상 기록'),
          for (final r in list)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${CareDate.date(r.date)} · ${app.personName(r.targetId)}님',
              ),
              subtitle: Text(r.type.label),
              value: selected.contains(r.id),
              onChanged: (v) => setState(() {
                v == true ? selected.add(r.id) : selected.remove(r.id);
                result = false;
              }),
            ),
          const SizedBox(height: 16),
          AppButton(
            label: '선택한 기록 확인',
            onPressed: selected.isEmpty
                ? null
                : () => setState(() => result = true),
          ),
          if (result) ...[
            const SectionTitle('포함된 상담 기록'),
            for (final r in list.where((r) => selected.contains(r.id))) ...[
              RecordTile(record: r),
              const SizedBox(height: 10),
            ],
            const InfoPanel(
              '체험 화면에서는 선택된 기록과 요약을 확인할 수 있습니다. 누적 AI 분석과 상태 변화 판단은 실제 분석 API를 연결한 뒤 제공됩니다.',
            ),
          ],
        ],
      ),
    );
  }
}
