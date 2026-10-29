import 'package:flutter/material.dart';

import '../../../../app/widgets/app_widgets.dart';

class CounselingEntryPage extends StatelessWidget {
  const CounselingEntryPage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    title: '후속 기능 미리보기',
    child: PageBody(
      children: [
        const InfoPanel(
          '영상·전화는 후속 단계, 채팅은 도입 시점 미정입니다. 아래 화면은 연결되지 않는 UI 미리보기입니다.',
        ),
        const SizedBox(height: 20),
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconBubble(Icons.videocam_outlined),
            title: const Text('영상 상담'),
            subtitle: const Text('후속 기능'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openPage(context, const CallPreviewPage()),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconBubble(Icons.phone_outlined),
            title: const Text('전화 상담'),
            subtitle: const Text('후속 기능'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                openPage(context, const CallPreviewPage(voiceOnly: true)),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconBubble(Icons.chat_bubble_outline),
            title: const Text('상담 채팅'),
            subtitle: const Text('도입 시점 미정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openPage(context, const ChatPreviewPage()),
          ),
        ),
      ],
    ),
  );
}

class CallPreviewPage extends StatefulWidget {
  const CallPreviewPage({super.key, this.voiceOnly = false});
  final bool voiceOnly;
  @override
  State<CallPreviewPage> createState() => _CallPreviewPageState();
}

class _CallPreviewPageState extends State<CallPreviewPage> {
  bool mic = true, camera = true, speaker = true;
  @override
  Widget build(BuildContext context) => AppPage(
    title: widget.voiceOnly ? '전화 상담' : '영상 상담',
    child: PageBody(
      children: [
        const StatusBadge('후속 기능 · 실제 연결 없음'),
        const SizedBox(height: 12),
        const Text('00:00', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: .76,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: const Color(0xFF344C45),
                  child: widget.voiceOnly || !camera
                      ? const Center(
                          child: PersonAvatar(size: 155, staff: true),
                        )
                      : Image.asset(
                          'assets/images/staff_avatar_v1.png',
                          fit: BoxFit.cover,
                        ),
                ),
                const Positioned(
                  right: 16,
                  top: 16,
                  child: PersonAvatar(size: 76),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '담당자와 함께하는 상담 화면',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '미리보기 · 마이크와 카메라를 실제로 사용하지 않습니다.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            IconButton.filled(
                              tooltip: mic ? '마이크 끄기' : '마이크 켜기',
                              onPressed: () => setState(() => mic = !mic),
                              icon: Icon(mic ? Icons.mic : Icons.mic_off),
                            ),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFDE5D54),
                              ),
                              tooltip: '미리보기 종료',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.call_end,
                                color: Colors.white,
                              ),
                            ),
                            IconButton.filled(
                              tooltip: widget.voiceOnly
                                  ? (speaker ? '스피커 끄기' : '스피커 켜기')
                                  : (camera ? '카메라 끄기' : '카메라 켜기'),
                              onPressed: () => setState(() {
                                if (widget.voiceOnly) {
                                  speaker = !speaker;
                                } else {
                                  camera = !camera;
                                }
                              }),
                              icon: Icon(
                                widget.voiceOnly
                                    ? (speaker
                                          ? Icons.volume_up
                                          : Icons.volume_off)
                                    : (camera
                                          ? Icons.videocam
                                          : Icons.videocam_off),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class ChatPreviewPage extends StatefulWidget {
  const ChatPreviewPage({super.key});
  @override
  State<ChatPreviewPage> createState() => _ChatPreviewPageState();
}

class _ChatPreviewPageState extends State<ChatPreviewPage> {
  final input = TextEditingController();
  final messages = <String>[];
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void send() {
    final value = input.text.trim();
    if (value.isEmpty) return;
    setState(() => messages.add(value));
    input.clear();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: '상담 채팅',
    footer: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            label: '체험 메시지',
            controller: input,
            maxLines: 2,
            textInputAction: TextInputAction.send,
            onFieldSubmitted: (_) => send(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: '체험 메시지 넣기',
          onPressed: send,
          icon: const Icon(Icons.send_outlined),
        ),
      ],
    ),
    child: PageBody(
      children: [
        const StatusBadge('도입 시점 미정 · 기기 내 미리보기'),
        const SizedBox(height: 16),
        const MessageBubble(
          name: '체험 담당자',
          text: '안녕하세요. 오늘은 어떤 도움이 필요하신가요?',
          staff: true,
          time: '예시',
        ),
        const MessageBubble(
          name: '나',
          text: '생활 지원 서비스를 확인하고 싶어요.',
          mine: true,
          time: '예시',
        ),
        const MessageBubble(
          name: '체험 담당자',
          text: '필요한 도움을 차근차근 확인해 볼게요.',
          staff: true,
          time: '예시',
        ),
        for (final m in messages)
          MessageBubble(name: '나', text: m, mine: true, time: '체험 입력 · 미전송'),
      ],
    ),
  );
}
