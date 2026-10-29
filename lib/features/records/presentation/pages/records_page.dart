import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/care_models.dart';
import '../../../appointments/presentation/pages/appointment_request_page.dart';
import '../../../analysis/presentation/pages/cumulative_analysis_page.dart';
import 'record_editor_page.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  VisitType? filter;
  String query = '';
  bool newest = true;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), data = CareScope.of(context).data;
    if (data == null) return const SizedBox.shrink();
    final records = data.records
        .where(
          (r) =>
              (filter == null || r.type == filter) &&
              '${app.personName(r.targetId)} ${r.summary} ${r.original}'
                  .contains(query),
        )
        .toList();
    if (!newest) records.sort((a, b) => a.date.compareTo(b.date));
    return PageBody(
      onRefresh: app.refresh,
      children: [
        SoftBanner(
          title: '안녕하세요,\n${app.user!.name}님 👋',
          message: '지금까지의 상담 기록을\n확인하고, 이어서 상담해 보세요.',
          height: 170,
        ),
        const SizedBox(height: 14),
        AppButton(
          label: app.isStaff ? '새 상담 기록 작성' : '새 상담 신청하기',
          icon: Icons.add,
          onPressed: () => openPage(
            context,
            app.isStaff
                ? const RecordEditorPage()
                : const AppointmentRequestPage(),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            labelText: '상담 기록 검색',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v.trim()),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('전체'),
              selected: filter == null,
              onSelected: (_) => setState(() => filter = null),
            ),
            for (final v in [VisitType.visit, VisitType.phone])
              ChoiceChip(
                label: Text(v.label),
                selected: filter == v,
                onSelected: (_) => setState(() => filter = v),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '상담 ${records.length}건',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton.icon(
              onPressed: () => setState(() => newest = !newest),
              icon: const Icon(Icons.swap_vert, size: 16),
              label: Text(newest ? '최신순' : '오래된순'),
            ),
          ],
        ),
        if (records.isEmpty) const EmptyView(title: '확인할 상담 기록이 없어요'),
        for (final r in records) ...[
          RecordTile(record: r),
          const SizedBox(height: 10),
        ],
        if (app.isStaff) ...[
          const SizedBox(height: 16),
          AppButton(
            label: '누적 상담 분석',
            variant: AppButtonVariant.secondary,
            onPressed: () => openPage(context, const CumulativeAnalysisPage()),
          ),
        ],
      ],
    );
  }
}
