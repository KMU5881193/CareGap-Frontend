import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/care_scope.dart';
import '../../../app/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';
import '../../../core/data/live_care_repository.dart';
import '../../../core/errors/app_exception.dart';

class LiveAnalysisPage extends StatefulWidget {
  const LiveAnalysisPage({
    super.key,
    required this.personId,
    this.current,
    this.analysis,
  });
  final String personId;
  final Json? current, analysis;
  @override
  State<LiveAnalysisPage> createState() => _LiveAnalysisPageState();
}

class _LiveAnalysisPageState extends State<LiveAnalysisPage> {
  late Json? analysis = widget.analysis;
  String? pastId, error;
  bool busy = false, evidenceChecked = false, needChecked = false;
  int? findingIndex, evidenceIndex;
  String? need;
  final confirmations = <Json>[];
  List<Json> recommendations = [];
  Timer? timer;
  int polls = 0;
  LiveCareRepository get repo =>
      CareScope.of(context).repository as LiveCareRepository;
  @override
  void initState() {
    super.initState();
    if (analysis?['status'] == 'running') startPolling();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startPolling() {
    timer?.cancel();
    polls = 0;
    timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || busy || analysis == null) return;
      await work(() async {
        analysis = await repo.getAnalysis(analysis!['id']);
      });
      if (analysis?['status'] != 'running' || error != null || ++polls >= 75) {
        timer?.cancel();
      }
    });
  }

  Future<void> work(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (e is AppException && e.code == '409' && analysis != null) {
        try {
          analysis = await repo.getAnalysis(analysis!['id']);
          evidenceChecked = false;
          confirmations.clear();
          recommendations = [];
        } catch (_) {}
      }
      if (mounted) error = '$e';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<Json> get findings => analysis?['edited'] is Map
      ? objects(object(analysis!['edited'])['findings'])
      : [];
  @override
  Widget build(BuildContext context) {
    final choices = repo
        .latestRecords(widget.personId)
        .where(
          (r) => r['consultation_id'] != widget.current?['consultation_id'],
        )
        .toList();
    final result = analysis,
        status = result?['status'],
        review = result?['review_state'];
    return AppPage(
      title: 'AI 분석 · 근거 검토',
      child: PageBody(
        children: [
          AppCard(
            color: const Color(0xFFFFF7E9),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'AI의 비교 결과를 원문과 함께 검토해 주세요. 진단이나 복지 수급 판정이 아닙니다.',
                  ),
                ),
                Image.asset(
                  'assets/images/ai_guide_v1.png',
                  width: 85,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.current != null) ...[
            const SectionTitle('현재 상담 원문'),
            AppCard(child: SelectableText(widget.current!['text'])),
            if (choices.isEmpty)
              const InfoPanel('비교하려면 같은 대상자의 서로 다른 상담 기록을 하나 이상 더 저장해야 합니다.')
            else ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: pastId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '비교할 이전 상담'),
                items: [
                  for (final r in choices)
                    DropdownMenuItem(
                      value: r['consultation_id'] as String,
                      child: Text(
                        r['text'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                        pastId = v;
                        analysis = null;
                        recommendations = [];
                        confirmations.clear();
                        evidenceChecked = false;
                      }),
              ),
              if (pastId != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: SelectableText(
                    choices.firstWhere(
                      (r) => r['consultation_id'] == pastId,
                    )['text'],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: 'AI 비교 분석 요청',
                isLoading: busy,
                onPressed: pastId == null
                    ? null
                    : () => work(() async {
                        final a = await repo.analyze(
                          widget.personId,
                          choices.firstWhere(
                            (r) => r['consultation_id'] == pastId,
                          ),
                          widget.current!,
                        );
                        if (!mounted) return;
                        analysis = a;
                        recommendations = [];
                        confirmations.clear();
                        evidenceChecked = false;
                        if (a['status'] == 'running') startPolling();
                      }),
              ),
            ],
          ],
          if (result != null) ...[
            const SizedBox(height: 16),
            StatusBadge(
              status == 'succeeded'
                  ? {
                          'draft': '검토 초안',
                          'review': '제출 완료',
                          'approved': '검토 승인',
                          'rejected': '반려',
                        }[review] ??
                        review
                  : status == 'failed'
                  ? '분석 실패'
                  : '분석 중',
            ),
            Text(
              '제공자: ${result['provider_kind']} · 모델: ${result['provider_metadata']?['model'] ?? '정보 없음'}',
            ),
            Text('분석 버전 ${result['version']}'),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: result['id']));
                if (context.mounted) toast(context, '분석 ID를 복사했어요.');
              },
              child: const Text('분석 ID 복사 · 다음 실행에서 다시 조회 가능'),
            ),
            AppButton(
              label: '분석 상태 새로고침',
              variant: AppButtonVariant.secondary,
              onPressed: busy
                  ? null
                  : () => work(() async {
                      analysis = await repo.getAnalysis(result['id']);
                    }),
            ),
            if (status == 'running')
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            if (status == 'failed')
              InfoPanel(
                '분석 실패: ${result['error_code'] ?? 'PROVIDER_ERROR'}\n검토·승인·추천을 진행할 수 없습니다. 근거가 충분한 합성 상담으로 다시 확인해 주세요.',
              ),
            if (status == 'succeeded') ...[
              const SectionTitle('분석 당시 상담 원문'),
              for (final source in objects(result['sources'])) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source['consultation_id'] ==
                                object(
                                  result['input'],
                                )['current']['consultation_id']
                            ? '현재 기록'
                            : '이전 기록',
                      ),
                      SelectableText(source['text']),
                      Text(
                        '버전 ${source['record_version_id']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SectionTitle('변화와 원문 근거'),
              for (int i = 0; i < findings.length; i++) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatusBadge(
                        {
                              'improved': '개선',
                              'worsened': '악화',
                              'unchanged': '변화 없음',
                              'unknown': '판단 근거 부족',
                            }[findings[i]['change']] ??
                            '알 수 없음',
                      ),
                      const SizedBox(height: 8),
                      SelectableText(findings[i]['text']),
                      if (review == 'draft')
                        TextButton(
                          onPressed: busy ? null : () => editFinding(i),
                          child: const Text('담당자 문구 수정'),
                        ),
                      for (
                        int j = 0;
                        j < objects(findings[i]['evidence']).length;
                        j++
                      ) ...[
                        const Divider(),
                        Text('근거 ${j + 1}'),
                        SelectableText(
                          '“${findings[i]['evidence'][j]['quote']}”',
                        ),
                        Text(
                          '기록 ${findings[i]['evidence'][j]['consultation_id']}\n버전 ${findings[i]['evidence'][j]['record_version_id']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SectionTitle('다음 상담에서 확인할 질문'),
              for (final q in object(result['edited'])['questions'] as List)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $q'),
                ),
              if (review == 'draft') ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: evidenceChecked,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => evidenceChecked = v ?? false),
                  title: const Text('이전·현재 원문과 모든 판단 근거를 대조했습니다.'),
                ),
                AppButton(
                  label: '검토 제출',
                  isLoading: busy,
                  onPressed: !evidenceChecked
                      ? null
                      : () => reviewAction('submit'),
                ),
              ],
              if (review == 'review') ...[
                const InfoPanel('검토가 제출됐습니다. 승인과 반려를 별도로 선택해 주세요.'),
                const SizedBox(height: 12),
                AppButton(
                  label: '담당자 최종 승인',
                  isLoading: busy,
                  onPressed: () => reviewAction('approve'),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: '분석 반려',
                  variant: AppButtonVariant.secondary,
                  onPressed: busy ? null : () => reviewAction('reject'),
                ),
              ],
              if (review == 'approved') ...recommendationForm(),
              if (review == 'rejected')
                const InfoPanel('반려된 분석은 복지 추천에 사용할 수 없습니다.'),
              if (object(result['original'])['findings'] != null)
                ExpansionTile(
                  title: const Text('모델 최초 분석 원문'),
                  children: [
                    SelectableText(
                      const JsonEncoder.withIndent('  ')
                          .convert(result['original']),
                    ),
                  ],
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

  Future<void> editFinding(int index) async {
    final changed = await askText(
      context,
      '분석 문구 수정',
      label: '근거를 바꾸지 않고 표현만 교정',
      initial: findings[index]['text'],
    );
    if (changed == null || changed.trim().isEmpty || !mounted) return;
    await work(() async {
      final draft = object(jsonDecode(jsonEncode(analysis!['edited'])));
      draft['findings'][index]['text'] = changed.trim();
      analysis = await repo.review(analysis!, 'edit', draft: draft);
      evidenceChecked = false;
    });
  }

  Future<void> reviewAction(String action) async {
    if (busy) return;
    if (!await confirmCare(
      context,
      {'submit': '검토 제출', 'approve': '최종 승인', 'reject': '분석 반려'}[action]!,
      action == 'approve'
          ? '원문 근거와 분석 의미가 일치하는지 확인했나요? 승인 후 분석을 수정할 수 없습니다.'
          : '이 상태 변경을 서버에 저장할까요?',
    )) {
      return;
    }
    if (!mounted) return;
    await work(() async {
      analysis = await repo.review(analysis!, action);
      evidenceChecked = false;
    });
  }

  List<Widget> recommendationForm() => [
    const SectionTitle('담당자가 확인한 지원 필요'),
    const InfoPanel(
      'AI 문구에서 필요를 자동 추출하지 않습니다. 지원 필요와 이를 뒷받침하는 실제 근거를 직접 선택해 주세요.',
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      initialValue: need,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '지원 필요'),
      items: const [
        DropdownMenuItem(value: 'meal_support', child: Text('식사 지원')),
        DropdownMenuItem(value: 'mobility_support', child: Text('이동 지원')),
        DropdownMenuItem(value: 'medication_management', child: Text('복약 관리')),
      ],
      onChanged: busy
          ? null
          : (v) => setState(() {
              need = v;
              needChecked = false;
            }),
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<int>(
      initialValue: findingIndex,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '판단 항목'),
      items: [
        for (int i = 0; i < findings.length; i++)
          DropdownMenuItem(
            value: i,
            child: Text(
              findings[i]['text'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: busy
          ? null
          : (v) => setState(() {
              findingIndex = v;
              evidenceIndex = null;
              needChecked = false;
            }),
    ),
    if (findingIndex != null) ...[
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        key: ValueKey(findingIndex),
        initialValue: evidenceIndex,
        isExpanded: true,
        decoration: const InputDecoration(labelText: '근거 문장'),
        items: [
          for (
            int j = 0;
            j < objects(findings[findingIndex!]['evidence']).length;
            j++
          )
            DropdownMenuItem(
              value: j,
              child: Text(
                findings[findingIndex!]['evidence'][j]['quote'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: busy
            ? null
            : (v) => setState(() {
                evidenceIndex = v;
                needChecked = false;
              }),
      ),
    ],
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: needChecked,
      onChanged: busy ? null : (v) => setState(() => needChecked = v ?? false),
      title: const Text('선택한 근거를 확인했고 해당 지원 필요를 인정합니다.'),
    ),
    AppButton(
      label: '확인한 필요 추가',
      variant: AppButtonVariant.secondary,
      onPressed:
          busy ||
              !needChecked ||
              need == null ||
              findingIndex == null ||
              evidenceIndex == null
          ? null
          : () => setState(() {
              confirmations.removeWhere((c) => c['need'] == need);
              confirmations.add({
                'need': need,
                'finding_index': findingIndex,
                'evidence_index': evidenceIndex,
                'confirmed': true,
              });
              needChecked = false;
              recommendations = [];
            }),
    ),
    for (final c in confirmations)
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          '${c['need']} · 판단 ${(c['finding_index'] as int) + 1} / 근거 ${(c['evidence_index'] as int) + 1}',
        ),
        trailing: IconButton(
          tooltip: '선택 제거',
          icon: const Icon(Icons.close),
          onPressed: busy
              ? null
              : () => setState(() {
                  confirmations.remove(c);
                  recommendations = [];
                }),
        ),
      ),
    const SizedBox(height: 16),
    AppButton(
      label: '합성 복지 후보 조회',
      isLoading: busy,
      onPressed: confirmations.isEmpty
          ? null
          : () => work(() async {
              final data = await repo.recommend(
                analysis!,
                List.of(confirmations),
              );
              recommendations = objects(data['candidates']);
              if (recommendations.isEmpty && mounted) {
                toast(context, '일치하는 합성 후보가 없습니다.');
              }
            }),
    ),
    for (final c in recommendations) ...[
      const SizedBox(height: 16),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBadge('합성 · 자격 미확인'),
            const SizedBox(height: 8),
            Text(
              c['program_name'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(c['reason']),
            const SizedBox(height: 8),
            Text(c['application_method']),
            for (final info in c['missing_information'] as List)
              Text('• $info'),
            Text(c['warning'] ?? '실제 신청 불가'),
          ],
        ),
      ),
    ],
  ];
}
