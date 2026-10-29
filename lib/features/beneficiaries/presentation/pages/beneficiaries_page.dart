import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../records/presentation/pages/record_detail_page.dart';
import '../../../records/presentation/pages/record_editor_page.dart';

class BeneficiariesPage extends StatelessWidget {
  const BeneficiariesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    if (!app.isStaff) {
      return const AppPage(
        title: '담당 대상자',
        child: EmptyView(title: '담당자만 이용할 수 있어요'),
      );
    }
    return AppPage(
      title: '담당 대상자',
      child: PageBody(
        children: [
          for (final person in app.data?.people ?? []) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const IconBubble(Icons.person_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${person.name}님',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '상담 기록 ${app.data!.records.where((r) => r.targetId == person.id).length}건',
                  ),
                  for (final r
                      in app.data!.records
                          .where((r) => r.targetId == person.id)
                          .take(3))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(CareDate.date(r.date)),
                      subtitle: Text(r.type.label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          openPage(context, RecordDetailPage(recordId: r.id)),
                    ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: '상담 기록 작성',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => openPage(
                      context,
                      RecordEditorPage(targetId: person.id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
