import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../analysis/presentation/pages/analysis_detail_page.dart';
import 'record_editor_page.dart';
import 'record_handover_page.dart';

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({super.key, required this.recordId});
  final String recordId;
  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    final r = app.data?.records
        .where((r) => r.id == widget.recordId)
        .firstOrNull;
    if (r == null) {
      return const AppPage(
        title: '상담 기록 상세',
        child: EmptyView(
          title: '기록에 접근할 수 없어요',
          message: '삭제·탈퇴·연결 상태와 공개 범위를 확인해 주세요.',
        ),
      );
    }
    return AppPage(
      title: '상담 기록 상세',
      actions: app.isStaff
          ? [
              PopupMenuButton<String>(
                tooltip: '기록 메뉴',
                onSelected: (v) => openPage(
                  context,
                  v == 'edit'
                      ? RecordEditorPage(recordId: r.id, targetId: r.targetId)
                      : RecordHandoverPage(recordId: r.id),
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('기록 수정')),
                  PopupMenuItem(value: 'handover', child: Text('기록 인계 요청')),
                ],
              ),
            ]
          : null,
      footer: AppButton(
        label: app.isStaff ? '기록 수정' : 'AI 분석 결과 보기',
        onPressed: () => openPage(
          context,
          app.isStaff
              ? RecordEditorPage(recordId: r.id, targetId: r.targetId)
              : AnalysisDetailPage(recordId: r.id),
        ),
      ),
      child: PageBody(
        children: [
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PersonAvatar(size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${app.personName(r.targetId)}님 상담',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CareDate.full(r.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(
                        r.analysis?.approved == true ? '검토 완료' : '검토 대기',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSegments<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('상담 내용')),
              ButtonSegment(value: 1, label: Text('AI 요약')),
              ButtonSegment(value: 2, label: Text('후속 조치')),
            ],
            selected: {tab},
            onSelectionChanged: (v) => setState(() => tab = v.first),
          ),
          const SizedBox(height: 16),
          if (tab == 0) ...[
            if (app.isStaff)
              for (final line
                  in r.original.split('\n').where((l) => l.trim().isNotEmpty))
                MessageBubble(
                  name: line.startsWith('담당자:')
                      ? '담당자'
                      : line.startsWith('대상자:')
                      ? '대상자'
                      : '상담 기록 원문',
                  text: line.replaceFirst(RegExp(r'^(담당자|대상자):\s*'), ''),
                  staff: line.startsWith('담당자:'),
                )
            else
              MessageBubble(name: '담당자가 확인한 공개 상담 요약', text: r.summary),
            if (app.isStaff && r.attachments.isNotEmpty) ...[
              const SectionTitle('첨부한 시험 파일'),
              for (final file in r.attachments) ...[
                if (file.kind == 'audio')
                  AudioPlayerCard(bytes: file.bytes, name: file.name)
                else
                  AppCard(
                    child: Column(
                      children: [
                        Image.memory(
                          file.bytes,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Text('사진을 표시할 수 없어요.'),
                        ),
                        Text(file.name),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ],
            if (app.isStaff && r.internalNote.isNotEmpty) ...[
              const SectionTitle('담당자 내부 메모'),
              InfoPanel(r.internalNote),
            ],
          ] else if (tab == 1) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 요약',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(r.analysis?.summary ?? '아직 분석 결과가 없습니다.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: '분석·근거 상세 보기',
              onPressed: () =>
                  openPage(context, AnalysisDetailPage(recordId: r.id)),
            ),
          ] else
            AppCard(
              child: Text(
                app.isStaff
                    ? (r.followup.isEmpty ? '등록된 후속 조치가 없습니다.' : r.followup)
                    : '공개된 요약에 포함된 후속 안내를 확인해 주세요.\n${r.summary}',
              ),
            ),
        ],
      ),
    );
  }
}
