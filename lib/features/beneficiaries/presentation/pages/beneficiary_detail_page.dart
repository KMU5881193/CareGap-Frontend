import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../records/presentation/pages/record_editor_page.dart';

class BeneficiaryDetailPage extends StatelessWidget {
  const BeneficiaryDetailPage({super.key, required this.targetId});
  final String targetId;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    final person = app.data?.people.where((p) => p.id == targetId).firstOrNull;
    if (person == null) {
      return const AppPage(
        title: '대상자 정보',
        child: EmptyView(title: '대상자 정보에 접근할 수 없어요'),
      );
    }
    return AppPage(
      title: '대상자 정보',
      child: PageBody(
        children: [
          const Center(child: PersonAvatar(size: 90)),
          const SizedBox(height: 18),
          Text(
            '${person.name}님',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DetailRow('생년월일', person.birthday),
                DetailRow('지역', person.region),
                DetailRow('담당자', person.staffName),
              ],
            ),
          ),
          const SectionTitle('상담 기록'),
          for (final r in app.data!.records.where(
            (r) => r.targetId == targetId,
          )) ...[RecordTile(record: r), const SizedBox(height: 12)],
          if (app.isStaff)
            AppButton(
              label: '기록 작성',
              onPressed: () =>
                  openPage(context, RecordEditorPage(targetId: targetId)),
            ),
        ],
      ),
    );
  }
}
