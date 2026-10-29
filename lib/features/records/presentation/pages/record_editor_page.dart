import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/models/care_models.dart';
import '../../../../core/models/frontend_models.dart';
import '../../../../core/utils/date_formatter.dart';
import 'record_import_page.dart';

class RecordEditorPage extends StatefulWidget {
  const RecordEditorPage({
    super.key,
    this.recordId,
    this.targetId,
    this.appointmentId,
  });
  final String? recordId, targetId, appointmentId;
  @override
  State<RecordEditorPage> createState() => _RecordEditorPageState();
}

class _RecordEditorPageState extends State<RecordEditorPage> {
  final form = GlobalKey<FormState>();
  final contentFocus = FocusNode();
  final content = TextEditingController(),
      note = TextEditingController(),
      followup = TextEditingController();
  final attachments = <MediaInput>[];
  bool initialized = false, busy = false;
  String? target, editingId;
  DateTime date = DateTime.now();
  VisitType type = VisitType.visit;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final app = CareScope.of(context);
    final r = app.data?.records
        .where(
          (r) => widget.recordId != null
              ? r.id == widget.recordId
              : widget.appointmentId != null &&
                    r.appointmentId == widget.appointmentId,
        )
        .firstOrNull;
    target = widget.targetId ?? r?.targetId ?? app.data?.people.firstOrNull?.id;
    editingId = r?.id;
    attachments.addAll(r?.attachments ?? []);
    content.text = r?.original ?? '';
    note.text = r?.internalNote ?? '';
    followup.text = r?.followup ?? '';
    date = r?.date ?? DateTime.now();
    type = r?.type ?? VisitType.visit;
    initialized = true;
  }

  @override
  void dispose() {
    contentFocus.dispose();
    content.dispose();
    note.dispose();
    followup.dispose();
    super.dispose();
  }

  Future<void> import(bool audio) async {
    if (attachments.length >= 4) {
      toast(context, '첨부는 4개까지 추가할 수 있어요.');
      return;
    }
    final value = await Navigator.push<RecordImportResult>(
      context,
      MaterialPageRoute(builder: (_) => RecordImportPage(audio: audio)),
    );
    if (value != null && mounted) {
      content.text =
          '${content.text}${content.text.isEmpty ? '' : '\n\n'}${value.text}';
      setState(() => attachments.add(value.file));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    if (!app.isStaff) {
      return const AppPage(
        title: '기록 작성',
        child: EmptyView(title: '담당자만 기록을 작성할 수 있어요'),
      );
    }
    return AppPage(
      title: editingId == null ? '상담 기록 작성' : '상담 기록 수정',
      child: PageBody(
        children: [
          const SectionTitle('기록 입력 방식'),
          QuickGrid(
            children: [
              QuickTile(
                title: '직접 작성',
                icon: Icons.edit_note,
                onTap: () => FocusScope.of(context).requestFocus(contentFocus),
              ),
              QuickTile(
                title: '사진 문자 추출',
                icon: Icons.add_photo_alternate_outlined,
                onTap: () => import(false),
              ),
              QuickTile(
                title: '녹음·음성 파일',
                icon: Icons.mic_none,
                onTap: () => import(true),
              ),
              QuickTile(
                title: '음성 변환 결과',
                icon: Icons.text_snippet_outlined,
                onTap: () => import(true),
              ),
            ],
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionTitle('첨부한 시험 파일'),
            for (final file in attachments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  file.kind == 'audio'
                      ? Icons.audio_file_outlined
                      : Icons.image_outlined,
                ),
                title: Text(file.name),
                subtitle: Text(
                  '${(file.bytes.length / 1024).ceil()}KB · 현재 실행 중에만 보관',
                ),
                trailing: IconButton(
                  tooltip: '첨부 삭제',
                  icon: const Icon(Icons.close),
                  onPressed: busy
                      ? null
                      : () => setState(() => attachments.remove(file)),
                ),
              ),
          ],
          const SizedBox(height: 24),
          Form(
            key: form,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: target,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '대상자'),
                  items: (app.data?.people ?? [])
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged:
                      busy || widget.targetId != null || editingId != null
                      ? null
                      : (v) => setState(() => target = v),
                  validator: (v) => v == null ? '대상자를 선택해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: CareDate.date(date),
                  icon: Icons.calendar_month_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: busy
                      ? null
                      : () async {
                          final d = await pickCareDate(context, date);
                          if (d != null && mounted) setState(() => date = d);
                        },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in [VisitType.visit, VisitType.phone])
                      ChoiceChip(
                        label: Text(v.label),
                        selected: type == v,
                        onSelected: busy
                            ? null
                            : (_) => setState(() => type = v),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: '상담 내용',
                  focusNode: contentFocus,
                  controller: content,
                  maxLines: 8,
                  enabled: !busy,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? '상담 내용을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: '후속 조치 (선택)',
                  controller: followup,
                  maxLines: 3,
                  enabled: !busy,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: '담당자 내부 메모 (선택)',
                  controller: note,
                  maxLines: 3,
                  enabled: !busy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const InfoPanel(
            '원문을 수정하면 이전 AI 검토 승인이 해제됩니다. 내부 메모는 대상자와 가족에게 제공하지 않습니다.',
          ),
          const SizedBox(height: 24),
          AppButton(
            label: '기록 저장',
            isLoading: busy,
            onPressed: () async {
              if (busy || !form.currentState!.validate() || target == null) {
                return;
              }
              setState(() => busy = true);
              final ok = await runCareTask(context, () async {
                await app.mutate(
                  (repo) => repo.saveRecord(
                    id: editingId,
                    targetId: target!,
                    original: content.text,
                    note: note.text,
                    followup: followup.text,
                    attachments: attachments,
                    date: date,
                    type: type,
                    appointmentId: widget.appointmentId,
                  ),
                );
              }, success: '체험 기록을 저장했어요.');
              if (!mounted || !context.mounted) return;
              setState(() => busy = false);
              if (ok) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
