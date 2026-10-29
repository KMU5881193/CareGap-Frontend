import 'package:flutter/material.dart';

import '../../../app/care_scope.dart';
import '../../../app/widgets/app_widgets.dart';
import '../../../core/data/live_care_repository.dart';

class LivePatientPage extends StatelessWidget {
  const LivePatientPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context),
        repo = app.repository as LiveCareRepository;
    final person = repo.persons.firstOrNull;
    return AppPage(
      title: '내 예약과 상담 기록',
      child: PageBody(
        onRefresh: app.refresh,
        children: [
          const InfoPanel(
            '합성 예약자 계정입니다. 본인의 예약과 기록만 표시합니다. 상담 기록 작성·AI 분석·승인은 담당자가 수행합니다.',
          ),
          const SizedBox(height: 16),
          if (person != null) ...[
            Text(
              repo.label(person['person_id']),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AsyncActionButton(
              label: '상담 예약',
              action: () async {
                final day = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2040),
                );
                if (day == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 14, minute: 0),
                );
                if (time == null) return;
                final start = DateTime(
                  day.year,
                  day.month,
                  day.day,
                  time.hour,
                  time.minute,
                );
                await repo.book(
                  person['person_id'],
                  start,
                  start.add(const Duration(hours: 1)),
                );
                await app.refresh();
              },
            ),
          ],
          for (final a in repo.appointments)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppCard(
                child: Text(
                  '${DateTime.parse(a['starts_at']).toLocal()} · ${a['status'] == 'scheduled' ? '예정' : '완료'}',
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text('내 상담 기록'),
          for (final r in repo.recordVersions)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppCard(child: SelectableText(r['text'])),
            ),
          const SizedBox(height: 20),
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
