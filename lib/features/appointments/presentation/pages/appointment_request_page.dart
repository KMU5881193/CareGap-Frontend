import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../core/models/care_models.dart';
import '../../../../core/models/frontend_models.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../app/widgets/app_widgets.dart';

class AppointmentRequestPage extends StatefulWidget {
  const AppointmentRequestPage({super.key, this.initial});
  final DateTime? initial;
  @override
  State<AppointmentRequestPage> createState() => _AppointmentRequestPageState();
}

class _AppointmentRequestPageState extends State<AppointmentRequestPage> {
  late DateTime date =
      widget.initial ?? DateTime.now().add(const Duration(days: 1));
  VisitType type = VisitType.visit;
  int hour = 14;
  String? targetId;
  bool busy = false;
  StaffAvailability? schedule;
  String? scheduleError;
  bool scheduleStarted = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!scheduleStarted) {
      scheduleStarted = true;
      loadSchedule();
    }
  }

  Future<void> loadSchedule() async {
    try {
      final value = await CareScope.of(context).repository.availability();
      if (mounted) {
        setState(() {
          schedule = value;
          scheduleError = null;
          if (!value.hours.contains(hour) && value.hours.isNotEmpty) {
            hour = value.hours.first;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => scheduleError = '$e');
    }
  }

  bool timeAvailable(int value) =>
      schedule != null &&
      schedule!.weekdays.contains(date.weekday) &&
      schedule!.hours.contains(value) &&
      !schedule!.blockedDates.contains(StaffAvailability.dateKey(date)) &&
      DateTime(date.year, date.month, date.day, value).isAfter(DateTime.now());

  final reason = TextEditingController(), place = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    reason.dispose();
    place.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (!timeAvailable(hour)) {
      toast(context, '상담 가능한 날짜와 시간을 선택해 주세요.');
      return;
    }
    final app = CareScope.of(context);
    final target =
        targetId ?? app.selectedTargetId ?? app.data?.people.firstOrNull?.id;
    if (target == null) {
      toast(context, '연결된 대상자를 선택해 주세요.');
      return;
    }
    final start = DateTime(date.year, date.month, date.day, hour);
    if (!start.isAfter(DateTime.now())) {
      toast(context, '앞으로의 날짜와 시간을 선택해 주세요.');
      return;
    }
    setState(() => busy = true);
    final confirmed = await confirmCare(
      context,
      '상담 신청 내용 확인',
      '${app.personName(target)}님\n${type.label}\n${CareDate.full(start)}\n${reason.text.trim()}\n${type == VisitType.visit ? place.text.trim() : '외부 전화 상담'}',
    );
    if (!mounted) return;
    if (!confirmed) {
      setState(() => busy = false);
      return;
    }
    final ok = await runCareTask(context, () async {
      await app.mutate(
        (repo) => repo.requestAppointment(
          targetId: target,
          start: start,
          type: type,
          reason: reason.text,
          place: place.text,
        ),
      );
    }, success: '상담을 요청했어요. 상대방의 응답을 기다려 주세요.');
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context),
        people = CareScope.of(context).data?.people ?? [];
    if (people.isEmpty && !app.loading) {
      return const AppPage(
        title: '상담 신청',
        child: EmptyView(title: '먼저 담당자와 연결해 주세요'),
      );
    }
    return AppPage(
      title: '상담 신청하기',
      child: PageBody(
        children: [
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (app.isStaff) ...[
                  DropdownButtonFormField<String>(
                    initialValue: targetId ?? people.firstOrNull?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '대상자'),
                    items: people
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (v) => setState(() => targetId = v),
                  ),
                  const SizedBox(height: 24),
                ],
                const SectionTitle('상담 종류'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in VisitType.values)
                      ChoiceChip(
                        label: Text(
                          '${value.label}${value == VisitType.video || value == VisitType.chat ? ' · 추후 지원' : ''}',
                        ),
                        selected: type == value,
                        onSelected:
                            busy ||
                                value == VisitType.video ||
                                value == VisitType.chat
                            ? null
                            : (_) => setState(() => type = value),
                      ),
                  ],
                ),
                const SectionTitle('날짜 및 시간'),
                if (scheduleError != null)
                  ErrorView(message: scheduleError!, onRetry: loadSchedule),
                if (schedule == null && scheduleError == null)
                  const LinearProgressIndicator(),
                AppButton(
                  label: CareDate.date(date),
                  icon: Icons.calendar_month_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: busy
                      ? null
                      : () async {
                          final selected = await pickCareDate(context, date);
                          if (selected != null && mounted) {
                            setState(() => date = selected);
                          }
                        },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final time
                        in (schedule?.hours.toList() ?? <int>[])..sort())
                      ChoiceChip(
                        label: Text('${time.toString().padLeft(2, '0')}:00'),
                        selected: hour == time,
                        onSelected: busy || !timeAvailable(time)
                            ? null
                            : (_) => setState(() => hour = time),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const InfoPanel('체험용 시간표입니다. 상담은 1시간 단위로 중복 여부를 확인합니다.'),
                const SectionTitle('상담 사유'),
                AppTextField(
                  label: '상담 사유 (선택)',
                  maxLength: 200,
                  controller: reason,
                  maxLines: 4,
                  enabled: !busy,
                  validator: (v) =>
                      (v?.length ?? 0) > 200 ? '200자 이하로 입력해 주세요.' : null,
                ),
                if (type == VisitType.visit) ...[
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '방문 장소',
                    controller: place,
                    enabled: !busy,
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? '방문 장소를 입력해 주세요.' : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(label: '신청 내용 확인', isLoading: busy, onPressed: submit),
        ],
      ),
    );
  }
}
