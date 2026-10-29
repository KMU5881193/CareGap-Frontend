import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/frontend_models.dart';
import '../../../../core/utils/date_formatter.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});
  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  Set<int> days = {}, hours = {};
  Set<String> blocked = {};
  bool loaded = false, busy = false;
  String? error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      loaded = true;
      load();
    }
  }

  Future<void> load() async {
    try {
      final v = await CareScope.of(context).repository.availability();
      if (!mounted) return;
      setState(() {
        days = {...v.weekdays};
        hours = {...v.hours};
        blocked = {...v.blockedDates};
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    if (!app.isStaff) {
      return const AppPage(
        title: '가능 시간 설정',
        child: EmptyView(title: '담당자만 이용할 수 있어요'),
      );
    }
    return AppPage(
      title: '상담 가능 시간',
      child: PageBody(
        children: [
          const InfoPanel('예약 가능 요일과 시간을 정해요. 체험 예약은 한 시간 단위로 확인합니다.'),
          if (error != null) ErrorView(message: error!, onRetry: load),
          const SectionTitle('상담 가능한 요일'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 1; i <= 7; i++)
                FilterChip(
                  label: Text(['월', '화', '수', '목', '금', '토', '일'][i - 1]),
                  selected: days.contains(i),
                  onSelected: (v) =>
                      setState(() => v ? days.add(i) : days.remove(i)),
                ),
            ],
          ),
          const SectionTitle('가능 시간'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 8; i <= 19; i++)
                FilterChip(
                  label: Text('${i.toString().padLeft(2, '0')}:00'),
                  selected: hours.contains(i),
                  onSelected: (v) =>
                      setState(() => v ? hours.add(i) : hours.remove(i)),
                ),
            ],
          ),
          const SectionTitle('휴가·예약 불가 날짜'),
          for (final date in blocked) ...[
            ListTile(
              title: Text(date),
              trailing: IconButton(
                tooltip: '날짜 제외 해제',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => blocked.remove(date)),
              ),
            ),
          ],
          AppButton(
            label: '예약 불가 날짜 추가',
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final d = await pickCareDate(context, DateTime.now());
              if (d != null && mounted) {
                setState(() => blocked.add(StaffAvailability.dateKey(d)));
              }
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: '가능 시간 저장',
            isLoading: busy,
            onPressed: () async {
              if (busy) return;
              setState(() => busy = true);
              await runCareTask(
                context,
                () => app.repository.saveAvailability(
                  StaffAvailability(
                    weekdays: days,
                    hours: hours,
                    blockedDates: blocked,
                  ),
                ),
                success: '상담 가능 시간을 저장했어요.',
              );
              if (mounted) setState(() => busy = false);
            },
          ),
          const SizedBox(height: 12),
          Text(
            '설정 기준일: ${CareDate.date(DateTime.now())}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
