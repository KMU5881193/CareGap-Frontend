import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';

class AccessibilityPage extends StatelessWidget {
  const AccessibilityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    return AppPage(
      title: '접근성 설정',
      child: PageBody(
        children: [
          const SectionTitle('글자 크기'),
          const Text('기기의 글자 크기에 앱 확대 배율을 추가해 적용합니다.'),
          const SizedBox(height: 18),
          Text('앱 확대 ${app.fontScale.toStringAsFixed(1)}배'),
          Slider(
            value: app.fontScale,
            min: 1,
            max: 1.6,
            divisions: 6,
            label: '${app.fontScale.toStringAsFixed(1)}배',
            onChanged: app.setFontScale,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('높은 대비'),
            subtitle: const Text('글자와 테두리의 대비를 높여요.'),
            value: app.highContrast,
            onChanged: app.setHighContrast,
          ),
          const SizedBox(height: 20),
          const AppCard(
            child: Text('돌봄이 필요한 순간, 함께 연결해요.\n필요한 정보를 편안하게 확인하세요.'),
          ),
          const SectionTitle('화면 읽기 안내'),
          const Text(
            'iPhone의 VoiceOver, Android의 TalkBack을 기기 접근성 설정에서 사용할 수 있습니다. 앱의 버튼과 상태에는 접근성 라벨을 제공합니다.',
          ),
        ],
      ),
    );
  }
}
