import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/care_scope.dart';
import '../../../app/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/media_validation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/data/live_care_repository.dart';
import '../../../core/models/frontend_models.dart';
import '../../../core/media/media_service.dart';

class LiveMediaPage extends StatefulWidget {
  const LiveMediaPage({
    super.key,
    required this.personId,
    required this.source,
  });
  final String personId, source;
  @override
  State<LiveMediaPage> createState() => _LiveMediaPageState();
}

class _LiveMediaPageState extends State<LiveMediaPage>
    with WidgetsBindingObserver {
  final capture = AudioCapture(), text = TextEditingController();
  final segments = <TextEditingController>[];
  List<Json> segmentRows = [];
  MediaInput? file;
  Json? job;
  Timer? timer;
  int polls = 0;
  String key = requestKey();
  bool busy = false, consent = false, dirty = true, adopting = false;
  String? error;
  LiveCareRepository get repo =>
      CareScope.of(context).repository as LiveCareRepository;
  String get source => widget.source;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    capture.addListener(captured);
  }

  void captured() {
    if (mounted) {
      setState(() {
        if (capture.result != null && file != capture.result) {
          file = capture.result;
          key = requestKey();
          job = null;
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && capture.recording) capture.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    capture.removeListener(captured);
    capture.dispose();
    text.dispose();
    for (final c in segments) {
      c.dispose();
    }
    super.dispose();
  }

  String get originalText => job?['original'] is String
      ? job!['original']
      : job?['original'] is Map
      ? (job!['original']['text'] ?? '')
      : '';
  void adopt(Json value) {
    job = value;
    if (value['status'] != 'succeeded') return;
    adopting = true;
    if (source == 'ocr') {
      final corrections = objects(value['corrections'] ?? []);
      text.text = corrections.isEmpty ? originalText : corrections.last['text'];
    } else {
      final revisions = objects(value['revisions'] ?? []);
      final rows = revisions.isEmpty
          ? objects(object(value['original'])['segments'])
          : objects(revisions.last['segments']);
      segmentRows = rows;
      for (final c in segments) {
        c.dispose();
      }
      segments.clear();
      for (final row in rows) {
        segments.add(
          TextEditingController(text: row['text'])..addListener(changed),
        );
      }
    }
    dirty = (value['version'] as num) == 0;
    adopting = false;
  }

  void changed() {
    if (!adopting && mounted) setState(() => dirty = true);
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (e is AppException && e.code == '409' && job != null && mounted) {
        try {
          final latest = await repo.getJob(source, job!['id']);
          if (mounted) adopt(latest);
        } catch (_) {}
      }
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> poll() async {
    if (!mounted || busy || job == null) return;
    await perform(() async {
      final next = await repo.getJob(source, job!['id']);
      if (!mounted) return;
      setState(() => adopt(next));
      if (!['pending', 'processing'].contains(next['status'])) timer?.cancel();
    });
    if (error != null) timer?.cancel();
    if (++polls >= 60) {
      timer?.cancel();
      if (mounted) {
        setState(
          () => error = '자동 확인을 잠시 멈췄어요. 작업 ID가 보존되어 있으니 상태 다시 확인을 눌러 주세요.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: source == 'ocr' ? '사진 문자 추출' : '음성 변환 · 교정',
    child: PageBody(
      children: [
        const InfoPanel(
          '합성 파일만 업로드하세요. 실제 모델의 인식 원문을 직접 확인·교정해야 합니다. STT 자동 화자 분리는 지원하지 않으며, 손글씨 정확도는 보장되지 않습니다.',
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: consent,
          onChanged: busy || job != null || capture.recording
              ? null
              : (v) => setState(() => consent = v ?? false),
          title: const Text('개인정보가 없는 합성 파일을 서버로 전송하는 데 동의합니다.'),
        ),
        if (job == null) ...[
          AppButton(
            label: '합성 시연 파일 사용',
            variant: AppButtonVariant.secondary,
            onPressed: busy || capture.recording
                ? null
                : () => perform(() async {
                    final name = source == 'ocr'
                        ? 'synthetic_note.png'
                        : 'synthetic_consultation.wav';
                    final bytes = await rootBundle.load('assets/demo/$name');
                    final input = MediaInput(
                      name: name,
                      bytes: bytes.buffer.asUint8List(
                        bytes.offsetInBytes,
                        bytes.lengthInBytes,
                      ),
                      kind: source == 'ocr' ? 'image' : 'audio',
                    );
                    validateUpload(source, input);
                    if (mounted) {
                      setState(() {
                        file = input;
                        key = requestKey();
                      });
                    }
                  }),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: '기존 작업 ID로 다시 열기',
            variant: AppButtonVariant.secondary,
            onPressed: busy
                ? null
                : () async {
                    final id = await askText(
                      context,
                      '인식 작업 다시 열기',
                      label: '이 대상자의 작업 ID',
                    );
                    if (id == null || id.trim().isEmpty || !mounted) return;
                    await perform(() async {
                      final value = await repo.getJob(source, id.trim());
                      if (value['person_id'] != widget.personId) {
                        throw const AppException('이 대상자의 작업이 아닙니다.');
                      }
                      if (mounted) {
                        setState(() => adopt(value));
                        if (['pending', 'processing'].contains(value['status'])) {
                          timer = Timer.periodic(
                            const Duration(seconds: 2),
                            (_) => poll(),
                          );
                        }
                      }
                    });
                  },
          ),
          const SizedBox(height: 12),

          AppButton(
            label: source == 'ocr' ? '사진 선택' : 'WAV 음성 파일 선택',
            variant: AppButtonVariant.secondary,
            onPressed: busy || capture.recording
                ? null
                : () => perform(() async {
                    final next = source == 'ocr'
                        ? await MediaSelectionService.instance.selectImage()
                        : await MediaSelectionService.instance.selectAudio();
                    if (next != null && mounted) {
                      validateUpload(source, next);
                      setState(() {
                        file = next;
                        key = requestKey();
                      });
                    }
                  }),
          ),
          if (source == 'stt') ...[
            const SizedBox(height: 12),
            AppButton(
              label: capture.recording
                  ? '녹음 중지 · ${capture.seconds}초'
                  : '합성 상담 녹음 (최대 2분)',
              onPressed: busy || !consent
                  ? null
                  : () => perform(() async {
                      if (capture.recording) {
                        await capture.stop();
                      } else {
                        await capture.start();
                      }
                    }),
            ),
            if (capture.error != null) InfoPanel(capture.error!),
          ],
          if (file != null) ...[
            const SizedBox(height: 16),
            Text('${file!.name} · ${(file!.bytes.length / 1024).ceil()}KB'),
            if (source == 'ocr')
              Image.memory(
                file!.bytes,
                height: 160,
                errorBuilder: (_, _, _) => const Text('이미지 표시 실패'),
              )
            else
              AudioPlayerCard(bytes: file!.bytes, name: file!.name),
            const SizedBox(height: 16),
            AppButton(
              label: '실제 인식 요청',
              isLoading: busy,
              onPressed: !consent || capture.recording
                  ? null
                  : () => perform(() async {
                      validateUpload(source, file!);
                      final next = await repo.createJob(
                        source,
                        widget.personId,
                        file!,
                        key,
                      );
                      if (!mounted) return;
                      setState(() => adopt(next));
                      polls = 0;
                      timer = Timer.periodic(
                        const Duration(seconds: 2),
                        (_) => poll(),
                      );
                    }),
            ),
          ],
        ],
        if (job != null) ...[
          const SizedBox(height: 16),
          StatusBadge(
            {
                  'pending': '대기',
                  'processing': '인식 중',
                  'succeeded': '인식 완료',
                  'failed': '인식 실패',
                }[job!['status']] ??
                job!['status'],
          ),
          SelectableText('작업 ID: ${job!['id']}'),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: job!['id']));
              if (context.mounted) toast(context, '작업 ID를 복사했어요.');
            },
            child: const Text('작업 ID 복사'),
          ),
          Text('교정 버전: ${job!['version']} · 제공자: ${job!['provider_kind']}'),
          const SizedBox(height: 12),
          AppButton(
            label: '작업 상태 다시 확인',
            variant: AppButtonVariant.secondary,
            onPressed: busy
                ? null
                : () async {
                    if (job?['status'] == 'succeeded' &&
                        dirty &&
                        !await confirmCare(
                          context,
                          '교정문 다시 불러오기',
                          '저장하지 않은 교정문을 서버의 최신 내용으로 바꿀까요?',
                        )) {
                      return;
                    }
                    await poll();
                  },
          ),
          if (['pending', 'processing'].contains(job!['status']))
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          if (job!['status'] == 'failed')
            AppButton(
              label: '다른 파일로 다시 인식',
              onPressed: busy
                  ? null
                  : () => setState(() {
                      job = null;
                      key = requestKey();
                      error = null;
                      timer?.cancel();
                    }),
            ),
          if (job!['status'] == 'failed')
            InfoPanel(
              '서버 인식 실패: ${job!['failure']?['code'] ?? 'PROVIDER_ERROR'}',
            ),
          if (job!['status'] == 'succeeded') ...[
            const SectionTitle('모델 인식 원문 · 수정되지 않음'),
            AppCard(child: SelectableText(originalText)),
            const SectionTitle('담당자 교정'),
            if (source == 'ocr')
              AppTextField(
                label: '교정문',
                controller: text,
                maxLines: 8,
                enabled: !busy && job!['confirmed'] == null,
                onChanged: (_) => changed(),
              )
            else ...[
              const InfoPanel('원래 시간 구간을 유지하며 문장별로 수정합니다. 화자는 미분리 상태입니다.'),
              for (int i = 0; i < segments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppTextField(
                    label: '구간 ${i + 1} 교정문',
                    controller: segments[i],
                    maxLines: 3,
                    enabled: !busy && job!['confirmed'] == null,
                  ),
                ),
            ],
            const SizedBox(height: 16),
            if (job!['confirmed'] == null)
              AppButton(
                label: '교정 내용 저장',
                isLoading: busy,
                onPressed: () => perform(() async {
                  final original = segmentRows;
                  final rows = [
                    for (int i = 0; i < segments.length; i++)
                      {...original[i], 'text': segments[i].text.trim()},
                  ];
                  final value = await repo.correctJob(
                    source,
                    job!,
                    text.text.trim(),
                    segments: rows,
                  );
                  if (mounted) {
                    setState(() {
                      job = value;
                      dirty = false;
                    });
                  }
                }),
              ),
            const SizedBox(height: 12),
            if (job!['confirmed'] == null)
              AppButton(
                label: '교정문 확인 · 확정',
                variant: AppButtonVariant.secondary,
                onPressed: busy || dirty || (job!['version'] as num) < 1
                    ? null
                    : () async {
                        if (!await confirmCare(
                          context,
                          '교정 확정',
                          '모델 원문과 교정문을 대조했나요? 확정 후에는 이 작업을 수정할 수 없습니다.',
                        )) {
                          return;
                        }
                        if (!mounted) return;
                        await perform(() async {
                          final value = await repo.confirmJob(source, job!);
                          if (mounted) setState(() => job = value);
                        });
                      },
              )
            else
              AppButton(
                label: '확정된 결과를 상담 기록으로 저장',
                isLoading: busy,
                onPressed: () => perform(() async {
                  final record = await repo.importJob(source, job!);
                  if (!mounted || !context.mounted) return;
                  Navigator.pop(context, record);
                }),
              ),
          ],
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          InfoPanel(error!, color: const Color(0xFFC44949)),
        ],
      ],
    ),
  );
}
