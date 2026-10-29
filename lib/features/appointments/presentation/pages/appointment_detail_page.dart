import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../core/models/care_models.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../records/presentation/pages/record_editor_page.dart';

class AppointmentDetailPage extends StatelessWidget {
  const AppointmentDetailPage({super.key, required this.appointmentId});
  final String appointmentId;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    final a = app.data?.appointments
        .where((a) => a.id == appointmentId)
        .firstOrNull;
    if (a == null) {
      return const AppPage(
        title: '상담 상세',
        child: EmptyView(
          title: '일정에 접근할 수 없어요',
          message: '삭제되었거나 연결이 해제되었을 수 있습니다.',
        ),
      );
    }
    final active = [
      AppointmentStatus.requested,
      AppointmentStatus.confirmed,
      AppointmentStatus.changeRequested,
    ].contains(a.status);
    final response =
        [
          AppointmentStatus.requested,
          AppointmentStatus.changeRequested,
        ].contains(a.status) &&
        app.user!.id != a.requesterId &&
        app.isStaff != (a.requesterId == 'staff');
    Future<void> action(String value, {String comment = '', DateTime? start}) =>
        app.mutate(
          (repo) => repo.appointmentAction(
            a.id,
            value,
            comment: comment,
            start: start,
          ),
        );
    return AppPage(
      title: '상담 상세',
      child: PageBody(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(a.status.label),
          ),
          const SizedBox(height: 16),
          Text(
            CareDate.full(a.start),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DetailRow('대상자', '${app.personName(a.targetId)}님'),
                DetailRow('상담 방식', a.type.label),
                DetailRow(
                  '담당자',
                  app.data!.people
                          .where((p) => p.id == a.targetId)
                          .firstOrNull
                          ?.staffName ??
                      '미연결',
                ),
                DetailRow('상담 사유', a.reason),
                if (a.type == VisitType.visit) DetailRow('장소', a.place),
                if (a.comment.isNotEmpty) DetailRow('처리 사유·코멘트', a.comment),
              ],
            ),
          ),
          if (a.proposedStart != null) ...[
            const SizedBox(height: 16),
            InfoPanel(
              '변경 요청: ${CareDate.full(a.proposedStart!)}\n상대방이 수락하기 전까지 기존 확정 시간을 유지합니다.',
            ),
          ],
          const SizedBox(height: 24),
          if (response) ...[
            AsyncActionButton(
              label: '요청 수락',
              action: () => action('accept'),
              success: '요청을 수락했어요.',
            ),
            const SizedBox(height: 12),
            AsyncActionButton(
              label: '요청 거절',
              secondary: true,
              action: () async {
                if (await confirmCare(context, '요청 거절', '이 상담 요청을 거절할까요?')) {
                  await action('reject');
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          if (a.status == AppointmentStatus.confirmed) ...[
            AsyncActionButton(
              label: '일정 변경 요청',
              secondary: true,
              action: () async {
                final day = await pickCareDate(context, a.start);
                if (!context.mounted || day == null) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(a.start),
                  helpText: '변경 시간 선택',
                  cancelText: '취소',
                  confirmText: '선택',
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
                if (!context.mounted || time == null) return;
                await action(
                  'change',
                  start: DateTime(
                    day.year,
                    day.month,
                    day.day,
                    time.hour,
                    time.minute,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          if (active) ...[
            AsyncActionButton(
              label: '상담 취소',
              secondary: true,
              action: () async {
                final reason = await askText(context, '상담 취소', label: '취소 사유');
                if (reason != null) await action('cancel', comment: reason);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (app.isStaff &&
              a.status == AppointmentStatus.confirmed &&
              !a.start.isAfter(DateTime.now())) ...[
            AsyncActionButton(
              label: '상담 완료',
              action: () async {
                final comment = await askText(
                  context,
                  '상담 완료',
                  label: '완료 코멘트',
                );
                if (comment != null) await action('complete', comment: comment);
              },
            ),
            const SizedBox(height: 12),
            AsyncActionButton(
              label: '불참 처리',
              secondary: true,
              action: () async {
                if (await confirmCare(context, '불참 처리', '이 상담을 불참으로 표시할까요?')) {
                  await action('absent');
                }
              },
            ),
          ],
          if (app.isStaff && a.status == AppointmentStatus.completed)
            AppButton(
              label: '연결된 상담 기록 작성',
              onPressed: () => openPage(
                context,
                RecordEditorPage(targetId: a.targetId, appointmentId: a.id),
              ),
            ),
          if (a.type == VisitType.phone)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: InfoPanel(
                '현재 전화 상담은 앱 외부에서 진행합니다. 앱 내 전화·영상 기능은 후속 단계입니다.',
              ),
            ),
        ],
      ),
    );
  }
}
