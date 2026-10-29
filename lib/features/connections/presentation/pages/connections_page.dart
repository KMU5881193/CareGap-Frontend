import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/models/care_models.dart';
import '../../../../app/widgets/app_widgets.dart';
import 'family_request_page.dart';

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), data = CareScope.of(context).data;
    final family = app.user?.role == UserRole.family;
    return AppPage(
      title: '가족·담당자 연결',
      child: PageBody(
        children: [
          Image.asset(
            'assets/images/family_care_v1.png',
            height: 200,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          Text(
            '함께 연결되어,\n더 든든한 돌봄',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (family) ...[
            const SectionTitle('선택한 대상자'),
            for (final person in app.linkedPeople) ...[
              AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const IconBubble(Icons.person_outline),
                  title: Text(person.name),
                  subtitle: Text(
                    person.id == app.selectedTargetId ? '현재 선택됨' : '연결 허용 완료',
                  ),
                  trailing: Icon(
                    person.id == app.selectedTargetId
                        ? Icons.check_circle
                        : Icons.chevron_right,
                  ),
                  onTap: () =>
                      runCareTask(context, () => app.selectTarget(person.id)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const InfoPanel(
              '가족의 활동은 대상자 본인의 활동과 구분해 기록합니다. 연결이 해제되면 해당 정보에 접근할 수 없습니다.',
            ),
          ],
          const SectionTitle('함께하는 돌봄'),
          const AppCard(
            child: Column(
              children: [
                DetailRow('일정 함께 보기', '확정된 상담 일정을 확인해요.'),
                DetailRow('상담 기록 공유', '공개된 상담 요약과 검토 결과를 확인해요.'),
                DetailRow('함께 돌보는 안심 케어', '대상자의 허용 범위에서 이용해요.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: family ? '가족 연결 요청하기' : '가족 초대 안내',
            onPressed: () => openPage(context, const FamilyRequestPage()),
          ),
          const SectionTitle('연결된 담당자'),
          for (final person
              in data?.people.where(
                    (p) =>
                        app.selectedTargetId == null ||
                        p.id == app.selectedTargetId,
                  ) ??
                  <Beneficiary>[]) ...[
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconBubble(Icons.badge_outlined),
                title: Text(person.staffName),
                subtitle: Text('${person.name}님 담당'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (app.user?.role == UserRole.beneficiary) ...[
            const SectionTitle('가족 연결 관리'),
            if (data?.links.isEmpty ?? true)
              const InfoPanel('연결된 가족이나 허용 대기 요청이 없습니다.'),
            for (final link in data?.links ?? []) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      link.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(link.pending ? '허용 대기' : '연결됨'),
                    ),
                    const SizedBox(height: 12),
                    AsyncActionButton(
                      label: link.pending ? '연결 허용' : '연결 해제',
                      secondary: !link.pending,
                      action: () async {
                        final ok = await confirmCare(
                          context,
                          link.pending ? '가족 연결 허용' : '가족 연결 해제',
                          link.pending
                              ? '이 가족이 허용된 상담 정보와 기능을 이용하도록 할까요?'
                              : '연결을 해제하면 이 가족의 정보 접근이 차단됩니다.',
                        );
                        if (ok) {
                          await app.mutate(
                            (repo) => repo.familyAction(
                              link.userId,
                              link.targetId,
                              link.pending,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}
