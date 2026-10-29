import 'package:flutter/material.dart';

import '../../../app/care_scope.dart';
import '../../../app/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/media_validation.dart';
import '../../../core/data/live_care_repository.dart';
import '../../../core/media/media_service.dart';
import '../../../core/models/frontend_models.dart';

class LiveVisionPage extends StatefulWidget {
  const LiveVisionPage({super.key, required this.personId});
  final String personId;
  @override
  State<LiveVisionPage> createState() => _LiveVisionPageState();
}

class _LiveVisionPageState extends State<LiveVisionPage> {
  MediaInput? file;
  Json? result;
  String key = requestKey();
  bool consent = false, busy = false;
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Vision 이미지 직접 분석',
    child: PageBody(
      children: [
        const InfoPanel(
          '선택 기능입니다. OCR을 거치지 않고 이미지를 Qwen에 전달합니다. 결과는 자동 저장·승인되지 않으며 시각 근거와 불확실성을 사람이 확인해야 합니다. 연결 서버가 지원하지 않으면 오류를 표시합니다.',
        ),
        const SizedBox(height: 16),
        AppButton(
          label: '합성 이미지 선택',
          onPressed: busy
              ? null
              : () async {
                  final selected = await MediaSelectionService.instance
                      .selectImage();
                  if (selected == null || !mounted) return;
                  setState(() {
                    file = selected;
                    key = requestKey();
                    result = null;
                  });
                },
        ),
        if (file != null) Text(file!.name),
        CheckboxListTile(
          value: consent,
          onChanged: busy ? null : (v) => setState(() => consent = v ?? false),
          title: const Text('개인정보가 없는 합성 이미지임을 확인했습니다.'),
        ),
        AppButton(
          label: 'Vision 분석 실행',
          isLoading: busy,
          onPressed: busy || !consent || file == null
              ? null
              : () async {
                  setState(() => busy = true);
                  await runCareTask(context, () async {
                    validateUpload('ocr', file!);
                    final value =
                        await (CareScope.of(context).repository
                                as LiveCareRepository)
                            .analyzeImage(widget.personId, file!, key);
                    if (mounted) {
                      setState(() => result = object(value['result']));
                    }
                  });
                  if (mounted) setState(() => busy = false);
                },
        ),
        if (result != null) ...[
          const SizedBox(height: 16),
          SelectableText(result!['care_note']),
          for (final o in objects(result!['observations']))
            ListTile(
              title: Text(o['text']),
              subtitle: Text('시각 근거: ${o['evidence']} · 확신 ${o['confidence']}'),
            ),
          for (final u in result!['uncertainties']) Text('불확실: $u'),
          InfoPanel(result!['safety_notice']),
        ],
      ],
    ),
  );
}
