import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';

class BeneficiarySelectionPage extends StatelessWidget {
  const BeneficiarySelectionPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '대상자 선택',
      protected: false,
      child: PageBody(
        children: [
          Text('누구의 돌봄을 확인할까요?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          for (final person in app.linkedPeople) ...[
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconBubble(Icons.person_outline),
                title: Text(person.name),
                subtitle: const Text('연결 허용 완료'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    runCareTask(context, () => app.selectTarget(person.id)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          AsyncActionButton(
            label: '로그아웃',
            secondary: true,
            action: app.signOut,
          ),
        ],
      ),
    );
  }
}
