import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/widgets/app_widgets.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    title: '도움말 / 고객센터',
    child: PageBody(
      children: [
        const SoftBanner(
          title: '무엇을 도와드릴까요?',
          message: '돌봄틈새 AI 이용 방법을 안내합니다.',
          asset: 'ai_guide_v1.png',
        ),
        const SectionTitle('자주 묻는 질문'),
        for (final item in const [
          [
            '상담은 어떻게 신청하나요?',
            '홈의 상담 예약 또는 일정의 상담 신청에서 방식·날짜·시간·사유를 입력해 주세요. 상대방의 수락 후 확정됩니다.',
          ],
          [
            '가족은 어떤 정보를 볼 수 있나요?',
            '대상자가 연결을 허용한 뒤 공개된 상담 요약과 검토 결과를 확인할 수 있어요. 연결 해제 후에는 접근할 수 없습니다.',
          ],
          [
            'AI 분석은 진단인가요?',
            'AI는 상담 내용을 정리하는 참고 도구입니다. 담당자가 원문 근거를 확인하고 최종 판단합니다.',
          ],
          [
            '사진·음성 변환은 어떻게 하나요?',
            '담당자 기록 작성에서 사진 선택·촬영 또는 음성 파일·녹음을 선택하세요. 현재 체험 결과는 실제 파일 분석이 아닌 예시입니다.',
          ],
          [
            '기록이 사라졌어요.',
            '현재 체험 정보는 메모리에 보관합니다. 앱을 완전히 종료하거나 웹을 새로고침하면 초기화됩니다.',
          ],
          [
            '알림이 오지 않아요.',
            '현재는 알림 목록과 설정 화면을 체험할 수 있습니다. 실제 푸시는 Firebase/APNs 및 서버 발송 연결이 필요합니다.',
          ],
        ])
          AppCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: Text(item[0]),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(item[1]),
                ),
              ],
            ),
          ),
        const SectionTitle('문의·오류 신고'),
        const Text('실제 문의 채널은 소속 기관의 안내를 이용해 주세요. 체험 오류 설명은 아래에서 복사할 수 있습니다.'),
        const SizedBox(height: 16),
        AppButton(
          label: '오류 설명 작성',
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            final text = await askText(context, '오류 설명', label: '발생 화면과 재현 방법');
            if (text == null || !context.mounted) return;
            await Clipboard.setData(
              ClipboardData(text: '돌봄틈새 AI 체험 오류\n$text'),
            );
            if (context.mounted) {
              toast(context, '오류 설명을 복사했어요. 외부로 전송되지 않았습니다.');
            }
          },
        ),
      ],
    ),
  );
}
