import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../../core/media/media_service.dart';
import '../../../../core/models/frontend_models.dart';

class RecordImportPage extends StatefulWidget {
  const RecordImportPage({super.key, this.audio = false});
  final bool audio;
  @override
  State<RecordImportPage> createState() => _RecordImportPageState();
}

class _RecordImportPageState extends State<RecordImportPage>
    with WidgetsBindingObserver {
  final capture = AudioCapture(), text = TextEditingController();
  MediaInput? file;
  bool consent = false, busy = false;
  String? failure;
  int tab = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    file = MediaSelectionService.instance.takeRecovered();
    capture.addListener(changed);
  }

  void changed() {
    if (mounted) {
      setState(() {
        if (capture.result != null) file = capture.result;
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
    capture.removeListener(changed);
    capture.dispose();
    text.dispose();
    super.dispose();
  }

  Future<void> choose({bool camera = false}) async {
    await runCareTask(context, () async {
      final chosen = widget.audio
          ? await MediaSelectionService.instance.selectAudio()
          : await MediaSelectionService.instance.selectImage(camera: camera);
      if (chosen != null && mounted) {
        setState(() {
          file = chosen;
          text.clear();
          failure = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    if (!app.isStaff) {
      return const AppPage(
        title: '기록 가져오기',
        child: EmptyView(title: '담당자만 이용할 수 있어요'),
      );
    }
    return AppPage(
      title: widget.audio ? '음성 변환 결과' : '사진 문자 추출',
      child: PageBody(
        children: [
          const InfoPanel(
            '허용된 시험 파일만 선택해 주세요. 현재 변환 결과는 체험 예시이며 실제 파일을 분석하거나 서버로 전송하지 않습니다.',
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: busy || capture.recording
                ? null
                : (v) => setState(() => consent = v ?? false),
            title: const Text('파일 제공과 녹음·변환에 필요한 안내 및 동의를 확인했습니다.'),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: widget.audio ? '음성 파일 선택' : '사진 선택',
            variant: AppButtonVariant.secondary,
            onPressed: busy || capture.recording ? null : () => choose(),
          ),
          const SizedBox(height: 12),
          if (!widget.audio)
            AppButton(
              label: '사진 촬영',
              variant: AppButtonVariant.secondary,
              onPressed: busy ? null : () => choose(camera: true),
            )
          else
            AppButton(
              label: capture.recording
                  ? '녹음 중지 · ${capture.seconds}초'
                  : '마이크로 녹음',
              icon: capture.recording
                  ? Icons.stop_circle_outlined
                  : Icons.mic_none,
              onPressed: busy || !consent
                  ? null
                  : () async {
                      await runCareTask(context, () async {
                        if (capture.recording) {
                          await capture.stop();
                        } else {
                          await capture.start();
                        }
                      });
                    },
            ),
          if (capture.recording) ...[
            const SizedBox(height: 12),
            const InfoPanel(
              '녹음 중입니다. 최대 2분 후 자동 중지하고 앱이 배경으로 이동하면 중지합니다.',
              color: Color(0xFFC44949),
            ),
          ],
          if (capture.error != null) ...[
            const SizedBox(height: 12),
            InfoPanel(capture.error!, color: const Color(0xFFC44949)),
          ],
          if (file != null) ...[
            const SizedBox(height: 20),
            if (widget.audio)
              AudioPlayerCard(bytes: file!.bytes, name: file!.name)
            else
              AppCard(
                child: Column(
                  children: [
                    Image.memory(
                      file!.bytes,
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Text('미리보기를 표시할 수 없는 사진입니다.'),
                    ),
                    const SizedBox(height: 8),
                    Text(file!.name),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            AppButton(
              label: busy ? '변환 중' : '체험 변환 요청',
              isLoading: busy,
              onPressed: !consent || capture.recording
                  ? null
                  : () async {
                      if (busy) return;
                      setState(() {
                        busy = true;
                        failure = null;
                      });
                      try {
                        final result = await app.repository.convertMedia(file!);
                        if (mounted) setState(() => text.text = result.text);
                      } catch (e) {
                        if (mounted) setState(() => failure = '$e');
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
            ),
          ],
          if (failure != null) ...[
            const SizedBox(height: 16),
            InfoPanel(
              '$failure\n파일과 동의를 확인한 뒤 다시 요청해 주세요.',
              color: const Color(0xFFC44949),
            ),
          ],
          if (text.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            AppSegments<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('텍스트 변환')),
                ButtonSegment(value: 1, label: Text('확인 사항')),
              ],
              selected: {tab},
              onSelectionChanged: (v) => setState(() => tab = v.first),
            ),
            const SizedBox(height: 16),
            if (tab == 0)
              AppTextField(label: '변환 내용 확인·수정', controller: text, maxLines: 10)
            else
              const InfoPanel(
                '화자와 문장을 원본 파일과 비교하고 잘못된 부분을 수정하세요. 체험 예시는 실제 변환 결과가 아닙니다.',
              ),
            const SizedBox(height: 20),
            AppButton(
              label: '확인 후 기록에 넣기',
              onPressed: () {
                if (text.text.trim().isEmpty || file == null) {
                  toast(context, '변환 내용을 확인해 주세요.');
                  return;
                }
                Navigator.pop(
                  context,
                  RecordImportResult(text.text.trim(), file!),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
