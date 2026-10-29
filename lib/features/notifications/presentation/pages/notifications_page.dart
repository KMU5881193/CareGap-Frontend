import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../appointments/presentation/pages/appointment_detail_page.dart';
import '../../../records/presentation/pages/record_detail_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context),
        notices = CareScope.of(context).data?.notices ?? [];
    return AppPage(
      title: '알림',
      child: PageBody(
        onRefresh: app.refresh,
        children: [
          if (notices.isEmpty) const EmptyView(title: '새로운 알림이 없어요'),
          for (final n in notices) ...[
            AppCard(
              onTap: () async {
                final ok = await runCareTask(
                  context,
                  () => app.mutate((repo) => repo.markRead(n.id)),
                );
                if (!context.mounted || !ok || app.data == null) return;
                if (n.kind == 'appointment') {
                  openPage(
                    context,
                    AppointmentDetailPage(appointmentId: n.resourceId ?? ''),
                  );
                } else {
                  openPage(
                    context,
                    RecordDetailPage(recordId: n.resourceId ?? ''),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(n.read ? '읽음' : '새 알림'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(n.body),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
