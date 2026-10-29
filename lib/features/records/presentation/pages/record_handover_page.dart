import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/frontend_models.dart';

class RecordHandoverPage extends StatefulWidget {
  const RecordHandoverPage({super.key, required this.recordId});
  final String recordId;
  @override
  State<RecordHandoverPage> createState() => _RecordHandoverPageState();
}

class _RecordHandoverPageState extends State<RecordHandoverPage> {
  String receiver = '체험 담당자 A';
  List<HandoverRequest> requests = [];
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    final accessible =
        app.isStaff &&
        (app.data?.records.any((r) => r.id == widget.recordId) ?? false);
    if (!accessible) {
      return const AppPage(
        title: '상담 인계',
        child: EmptyView(title: '인계를 요청할 수 없어요'),
      );
    }
    return AppPage(
      title: '상담 기록 인계',
      child: PageBody(
        children: [
          const InfoPanel(
            '선택한 기록의 인계 요청을 남깁니다. 승인 주체·열람 기간·권한 회수 정책 확정 전에는 상대방의 접근 권한을 자동으로 만들지 않습니다.',
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: receiver,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '전달받을 담당자'),
            items: ['체험 담당자 A', '체험 담당자 B']
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => receiver = v);
            },
          ),
          const SizedBox(height: 24),
          AsyncActionButton(
            label: '인계 요청',
            action: () async {
              if (!await confirmCare(context, '인계 요청', '선택한 기록의 인계를 요청할까요?')) {
                return;
              }
              await app.repository.requestHandover(widget.recordId, receiver);
              final result = await app.repository.handovers();
              if (mounted) setState(() => requests = result);
            },
            success: '체험 인계 요청을 등록했어요.',
          ),
          const SectionTitle('요청 상태'),
          for (final h in requests.where((h) => h.recordId == widget.recordId))
            AppCard(child: Text('${h.receiver} · 승인 대기')),
        ],
      ),
    );
  }
}
