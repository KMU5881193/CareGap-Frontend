import 'package:flutter/material.dart';

import '../../../app/care_scope.dart';
import '../../../app/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';
import '../../../core/data/live_care_repository.dart';
import '../../../core/errors/app_exception.dart';
import 'live_media_page.dart';
import 'live_analysis_page.dart';
import 'live_vision_page.dart';

class LiveRecordPage extends StatefulWidget {
  const LiveRecordPage({super.key, required this.personId, this.record});
  final String personId;
  final Json? record;
  @override
  State<LiveRecordPage> createState() => _LiveRecordPageState();
}

class _LiveRecordPageState extends State<LiveRecordPage> {
  late final text = TextEditingController(text: widget.record?['text'] ?? '');
  late Json? current = widget.record;
  bool busy = false, consent = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), r = app.repository as LiveCareRepository;
    return AppPage(
      title: current == null ? '상담 기록 작성' : '상담 기록 · 버전 이력',
      child: PageBody(
        children: [
          Text(
            r.label(widget.personId),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const InfoPanel(
            '합성 상담 내용만 입력해 주세요. 현재 서버는 상담 원문과 기록 버전만 저장합니다. 날짜·방식·내부 메모·원본 파일 첨부 보관은 지원하지 않습니다.',
          ),
          const SizedBox(height: 20),
          if (current == null)
            QuickGrid(
              children: [
                QuickTile(
                  title: 'Vision 이미지 직접 분석',
                  subtitle: '선택 기능 · 사람 검토 필요',
                  icon: Icons.image_search,
                  onTap: () => openPage(
                    context,
                    LiveVisionPage(personId: widget.personId),
                  ),
                ),
                for (final source in ['ocr', 'stt'])
                  QuickTile(
                    title: source == 'ocr' ? '사진 문자 추출' : '녹음 · 음성 변환',
                    icon: source == 'ocr'
                        ? Icons.photo_camera_outlined
                        : Icons.mic_none,
                    onTap: busy
                        ? () {}
                        : () async {
                            final imported = await Navigator.push<Json>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveMediaPage(
                                  personId: widget.personId,
                                  source: source,
                                ),
                              ),
                            );
                            if (imported == null || !mounted) return;
                            current = imported;
                            text.text = imported['text'];
                            await app.refresh();
                            if (mounted) setState(() {});
                          },
                  ),
              ],
            ),
          const SizedBox(height: 20),
          AppTextField(
            label: '상담 원문',
            controller: text,
            maxLines: 10,
            enabled: !busy,
          ),
          if (current == null) ...[
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () => text.text =
                            '어제 식사는 두 번 했습니다. 약을 빠뜨렸습니다. 산책은 한 번 했습니다.',
                  child: const Text('이전 합성 예시 넣기'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => text.text =
                            '오늘 식사는 세 번 했습니다. 약을 빠뜨리지 않았습니다. 산책은 두 번 했습니다.',
                  child: const Text('현재 합성 예시 넣기'),
                ),
              ],
            ),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: busy
                ? null
                : (v) => setState(() => consent = v ?? false),
            title: const Text('실제 개인정보가 없는 합성 상담임을 확인했습니다.'),
          ),
          AppButton(
            label: current == null ? '상담 기록 저장' : '새 버전으로 저장',
            isLoading: busy,
            onPressed: !consent
                ? null
                : () async {
                    if (busy || text.text.trim().isEmpty) {
                      toast(context, '상담 내용을 입력해 주세요.');
                      return;
                    }
                    setState(() => busy = true);
                    final ok = await runCareTask(context, () async {
                      Json result;
                      try {
                        result = await r.writeRecord(
                          widget.personId,
                          text.text.trim(),
                          previous: current,
                        );
                      } on AppException catch (e) {
                        if (e.code == '409') await app.refresh();
                        rethrow;
                      }
                      current = result;
                      await app.refresh();
                    }, success: '서버에 기록을 저장했어요.');
                    if (!mounted) return;
                    setState(() => busy = false);
                    if (!ok) return;
                  },
          ),
          if (current != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: '서버 최신 버전으로 다시 불러오기',
              variant: AppButtonVariant.secondary,
              onPressed: busy
                  ? null
                  : () async {
                      if (!await confirmCare(
                        context,
                        '최신 버전 조회',
                        '현재 입력을 서버 최신 원문으로 바꿀까요? 저장하지 않은 수정은 사라집니다.',
                      )) {
                        return;
                      }
                      if (!mounted || !context.mounted) return;
                      await runCareTask(context, () async {
                        await app.refresh();
                        final latest = r
                            .latestRecords(widget.personId)
                            .where(
                              (r) =>
                                  r['consultation_id'] ==
                                  current!['consultation_id'],
                            )
                            .firstOrNull;
                        if (latest != null && mounted) {
                          setState(() {
                            current = latest;
                            text.text = latest['text'];
                            consent = false;
                          });
                        }
                      });
                    },
            ),
            const SizedBox(height: 20),
            AppButton(
              label: '이전 상담과 AI 비교',
              onPressed: busy
                  ? null
                  : () => openPage(
                      context,
                      LiveAnalysisPage(
                        personId: widget.personId,
                        current: current,
                      ),
                    ),
            ),
            const SectionTitle('불변 버전 이력'),
            for (final version
                in r
                    .recordsFor(widget.personId)
                    .where(
                      (v) =>
                          v['consultation_id'] == current!['consultation_id'],
                    )
                    .toList()
                    .reversed) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('버전 ID ${version['record_version_id']}'),
                    const SizedBox(height: 8),
                    SelectableText(version['text']),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}
