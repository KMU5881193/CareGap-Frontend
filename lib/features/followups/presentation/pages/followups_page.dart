import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';

class FollowupsPage extends StatelessWidget {
  const FollowupsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    if (!app.isStaff) {
      return const AppPage(
        title: '후속 확인',
        child: EmptyView(title: '담당자만 이용할 수 있어요'),
      );
    }
    return AppPage(
      title: '후속 확인',
      child: PageBody(
        children: [
          const InfoPanel('상담 후 확인할 일을 기록하고 완료 여부를 관리해요.'),
          const SizedBox(height: 20),
          for (final person in app.data?.people ?? []) ...[
            SectionTitle('${person.name}님'),
            for (final f in app.data!.followups.where(
              (f) => f.targetId == person.id,
            )) ...[
              AppCard(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(f.text),
                  subtitle: Text(f.done ? '확인 완료' : '확인 필요'),
                  value: f.done,
                  onChanged: (_) => runCareTask(
                    context,
                    () => app.mutate((repo) => repo.toggleFollowup(f.id)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            AsyncActionButton(
              label: '${person.name}님 확인 항목 추가',
              secondary: true,
              action: () async {
                final text = await askText(
                  context,
                  '후속 확인 추가',
                  label: '다음에 확인할 일',
                );
                if (text != null) {
                  await app.mutate((repo) => repo.addFollowup(person.id, text));
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
