import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../widgets/appointment_tile.dart';
import 'appointment_request_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();
  String mode = '월';
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), data = CareScope.of(context).data;
    if (data == null) return const SizedBox.shrink();
    final weekStart = DateTime(
      selected.year,
      selected.month,
      selected.day,
    ).subtract(Duration(days: selected.weekday % 7));
    final list = data.appointments
        .where(
          (a) => mode == '주'
              ? !a.start.isBefore(weekStart) &&
                    a.start.isBefore(weekStart.add(const Duration(days: 7)))
              : CareDate.sameDay(a.start, selected),
        )
        .toList();
    return PageBody(
      onRefresh: app.refresh,
      children: [
        AppSegments<String>(
          segments: const [
            ButtonSegment(value: '월', label: Text('월')),
            ButtonSegment(value: '주', label: Text('주')),
            ButtonSegment(value: '일', label: Text('일')),
          ],
          selected: {mode},
          onSelectionChanged: (v) => setState(() => mode = v.first),
        ),
        const SizedBox(height: 16),
        if (mode == '월')
          AppCard(
            child: AppCalendar(
              markedDates: data.appointments.map((a) => a.start).toList(),
              selected: selected,
              onSelect: (v) => setState(() => selected = v),
            ),
          )
        else
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '이전 기간',
                      onPressed: () => setState(
                        () => selected = selected.subtract(
                          Duration(days: mode == '주' ? 7 : 1),
                        ),
                      ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        mode == '주'
                            ? '${CareDate.short(weekStart)}부터 7일'
                            : CareDate.date(selected),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: '다음 기간',
                      onPressed: () => setState(
                        () => selected = selected.add(
                          Duration(days: mode == '주' ? 7 : 1),
                        ),
                      ),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => selected = DateTime.now()),
                  child: const Text('오늘'),
                ),
              ],
            ),
          ),
        SectionTitle(
          mode == '주'
              ? '이번 주 상담 ${list.length}건'
              : '${CareDate.short(selected)} 상담 ${list.length}건',
        ),
        if (list.isEmpty) const EmptyView(title: '등록된 상담이 없어요'),
        for (final a in list) ...[
          AppointmentTile(appointment: a),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        AppButton(
          label: '상담 신청하기',
          icon: Icons.add,
          onPressed: () =>
              openPage(context, AppointmentRequestPage(initial: selected)),
        ),
      ],
    );
  }
}
