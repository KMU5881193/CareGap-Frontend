import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/care_scope.dart';
import '../../../app/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';
import '../../../core/data/live_care_repository.dart';
import '../../notifications/presentation/pages/notification_settings_page.dart';
import '../../settings/presentation/pages/accessibility_page.dart';
import 'live_record_page.dart';
import '../../calls/presentation/call_page.dart';
import '../../calls/presentation/recording_library_page.dart';
import 'live_analysis_page.dart';

class LiveShellPage extends StatefulWidget {
  const LiveShellPage({super.key});
  @override
  State<LiveShellPage> createState() => _LiveShellPageState();
}

class _LiveShellPageState extends State<LiveShellPage> {
  int index = 0;
  String? selected;
  DateTime day = DateTime.now(), focused = DateTime.now();
  LiveCareRepository get repo =>
      CareScope.of(context).repository as LiveCareRepository;
  Future<void> task(Future<void> Function() work) async {
    await runCareTask(context, () async {
      await work();
      if (mounted) await CareScope.of(context).refresh();
    });
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), r = repo;
    if (!r.persons.any((p) => p['person_id'] == selected)) {
      selected = r.persons.firstOrNull?['person_id'];
    }
    final titles = ['케어노트', '상담 일정', '상담 기록', '복지 후보', '더보기'];
    return AppPage(
      title: titles[index],
      titleWidget: index == 0 ? const AppBrand(size: 30) : null,
      actions: [
        IconButton(
          tooltip: '인앱 알림',
          icon: Badge(
            isLabelVisible: r.notices.any((n) => n['read_at'] == null),
            child: const Icon(Icons.notifications_none),
          ),
          onPressed: () => openPage(context, const LiveNoticesPage()),
        ),
      ],
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: index,
        onSelected: (v) => setState(() => index = v),
      ),
      child: PageBody(
        onRefresh: app.refresh,
        children: [
          if (index < 4) ...[
            if (r.persons.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey(selected),
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '상담 대상자'),
                items: [
                  for (final p in r.persons)
                    DropdownMenuItem(
                      value: p['person_id'] as String,
                      child: Text(r.label(p['person_id'])),
                    ),
                ],
                onChanged: (v) => setState(() => selected = v),
              ),
            const SizedBox(height: 16),
          ],
          if (index == 0) ...home(),
          if (index == 1) ...calendar(),
          if (index == 2) ...records(),
          if (index == 3) ...welfare(),
          if (index == 4) ...more(),
        ],
      ),
    );
  }

  List<Widget> home() => [
    AppCard(
      color: const Color(0xFFEAF6F0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요,\n합성 시연 담당자님',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text('기록을 연결하고,\n근거를 함께 확인해요.'),
              ],
            ),
          ),
          Image.asset(
            'assets/images/care_hero_v1.png',
            width: 110,
            height: 140,
            fit: BoxFit.cover,
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    const InfoPanel(
      '실제 HTTP 서버와 연결됩니다. 합성 데이터 전용이며 서버 재시작 시 자료가 사라집니다. 복지 후보는 실제 신청할 수 없습니다.',
    ),
    const SizedBox(height: 16),
    AsyncActionButton(
      label: '합성 대상자 생성',
      action: () async {
        final id = await repo.createPerson();
        if (!mounted) return;
        await CareScope.of(context).refresh();
        if (mounted) setState(() => selected = id);
      },
    ),
    const SizedBox(height: 16),
    QuickGrid(
      children: [
        QuickTile(
          title: '상담 기록',
          subtitle:
              '${selected == null ? 0 : repo.latestRecords(selected!).length}건',
          icon: Icons.description_outlined,
          onTap: () => setState(() => index = 2),
        ),
        QuickTile(
          title: '상담 일정',
          subtitle: '${repo.appointments.length}건',
          icon: Icons.calendar_month,
          onTap: () => setState(() => index = 1),
        ),
        QuickTile(
          title: '후속 업무',
          subtitle: '${repo.tasks.where((t) => t['status'] == 'open').length}건',
          icon: Icons.checklist,
          onTap: () => openPage(context, const LiveTasksPage()),
        ),
        QuickTile(
          title: '음성 상담',
          icon: Icons.call_outlined,
          subtitle: '통화·녹음 보관함',
          onTap: () => openPage(context, const CallPage()),
        ),
        QuickTile(
          title: '서버 연결 확인',
          icon: Icons.cloud_done_outlined,
          onTap: () async {
            await runCareTask(context, () async {
              final h = await repo.health();
              if (mounted) {
                toast(
                  context,
                  '서버 ${h['status']} · 분석 제공자 ${object(h['providers'])['analysis']}',
                );
              }
            });
          },
        ),
      ],
    ),
    const SizedBox(height: 16),
    if (selected == null) const EmptyView(title: '합성 대상자를 먼저 만들어 주세요'),
    if (selected != null)
      AppButton(
        label: '새 상담 기록 작성',
        icon: Icons.add,
        onPressed: () => openPage(context, LiveRecordPage(personId: selected!)),
      ),
  ];
  List<Widget> records() => [
    if (selected == null)
      const EmptyView(title: '홈에서 합성 대상자를 먼저 생성해 주세요')
    else ...[
      AppButton(
        label: '상담 기록 작성 · OCR/STT',
        icon: Icons.add,
        onPressed: () => openPage(context, LiveRecordPage(personId: selected!)),
      ),
      const SizedBox(height: 16),
      const InfoPanel(
        '기록은 서버 반환 순서로 표시합니다. 현재 API는 상담 일시와 상담 유형을 저장하지 않습니다. 수정 시 이전 버전이 보존됩니다.',
      ),
      const SizedBox(height: 16),
      if (repo.latestRecords(selected!).isEmpty)
        const EmptyView(title: '저장된 상담 기록이 없어요'),
      for (final record in repo.latestRecords(selected!).reversed) ...[
        AppCard(
          onTap: () => openPage(
            context,
            LiveRecordPage(personId: selected!, record: record),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusBadge('서버 저장'),
              const SizedBox(height: 10),
              Text(
                record['text'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                '기록 ${shortId(record['consultation_id'])} · 버전 ${repo.recordsFor(selected!).where((r) => r['consultation_id'] == record['consultation_id']).length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () => openPage(
                  context,
                  LiveAnalysisPage(personId: selected!, current: record),
                ),
                child: const Text('이전 기록과 분석 · 근거 검토'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  ];
  List<Widget> calendar() => [
    TableCalendar<Json>(
      locale: 'ko_KR',
      firstDay: DateTime(2020),
      lastDay: DateTime(2040),
      focusedDay: focused,
      selectedDayPredicate: (d) => isSameDay(d, day),
      onDaySelected: (d, f) => setState(() {
        day = d;
        focused = f;
      }),
      onPageChanged: (f) => focused = f,
      availableCalendarFormats: const {CalendarFormat.month: '월'},
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: const CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Color(0xFF278568),
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Color(0xFF7CB79D),
          shape: BoxShape.circle,
        ),
      ),
      eventLoader: (d) => repo.appointments
          .where((a) => isSameDay(DateTime.parse(a['starts_at']).toLocal(), d))
          .toList(),
    ),
    const SizedBox(height: 16),
    if (selected != null)
      AsyncActionButton(
        label: '선택한 날짜에 상담 예약',
        action: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 14, minute: 0),
          );
          if (time == null || !mounted) return;
          final start = DateTime(
            day.year,
            day.month,
            day.day,
            time.hour,
            time.minute,
          );
          await repo.book(
            selected!,
            start,
            start.add(const Duration(hours: 1)),
          );
          if (mounted) await CareScope.of(context).refresh();
          if (mounted) setState(() {});
        },
      ),
    const SizedBox(height: 12),
    const InfoPanel(
      '시간은 기기 현지 시간으로 표시하고 UTC로 전송합니다. 예약 길이는 1시간입니다. 상담 방식·장소·사유는 현재 서버 저장 항목이 아닙니다.',
    ),
    for (final a in repo.appointments.where(
      (a) => isSameDay(DateTime.parse(a['starts_at']).toLocal(), day),
    )) ...[
      const SizedBox(height: 12),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(repo.label(a['person_id'])),
            Text('${DateTime.parse(a['starts_at']).toLocal()}'),
            Text('${DateTime.parse(a['ends_at']).toLocal()} 종료'),
            StatusBadge(
              a['status'] == 'scheduled'
                  ? '예정'
                  : a['status'] == 'completed'
                  ? '완료'
                  : '취소',
            ),
            if (a['status'] == 'scheduled')
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () =>
                        task(() => repo.bookingAction(a, 'complete')),
                    child: const Text('상담 완료'),
                  ),
                  TextButton.icon(
                    onPressed: () => openPage(
                      context,
                      CallPage(appointmentId: a['appointment_id']),
                    ),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('음성 상담'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (await confirmCare(context, '예약 취소', '이 예약을 취소할까요?')) {
                        await task(() => repo.bookingAction(a, 'cancel'));
                      }
                    },
                    child: const Text('예약 취소'),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  ];
  List<Widget> welfare() => [
    const InfoPanel(
      '담당자가 분석 근거를 검토·승인하고 지원 필요를 직접 확인한 경우에만 후보를 조회합니다. 현재 카탈로그는 합성·자격 미확인·실제 신청 불가입니다.',
    ),
    const SizedBox(height: 16),
    if (selected != null)
      for (final a in repo.analyses.values.where(
        (a) => object(a['input'])['person_id'] == selected,
      )) ...[
        AppCard(
          onTap: () => openPage(
            context,
            LiveAnalysisPage(personId: selected!, analysis: a),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(a['review_state'] == 'approved' ? '검토 승인' : '검토 필요'),
              const SizedBox(height: 8),
              const Text('분석 근거와 복지 후보 확인'),
              for (final c in repo.candidates[a['id']] ?? <Json>[]) ...[
                const Divider(),
                Text(c['program_name']),
                Text(c['reason']),
                const Text('자격 미확인 · 실제 신청 불가'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    if (repo.analyses.isEmpty)
      const EmptyView(title: '상담 기록에서 비교 분석을 먼저 진행해 주세요'),
    const InfoPanel(
      '현재 서버에는 분석 목록·추천 이력 조회 API가 없어 이번 로그인에서 열어본 결과를 표시합니다. 분석 ID로 다시 열 수 있습니다.',
    ),
    const SizedBox(height: 12),
    AsyncActionButton(
      label: '분석 ID로 다시 열기',
      secondary: true,
      action: () async {
        final id = await askText(context, '분석 ID', label: '분석 ID');
        if (id == null || id.trim().isEmpty) return;
        final a = await repo.getAnalysis(id.trim());
        if (mounted) {
          openPage(
            context,
            LiveAnalysisPage(
              personId: object(a['input'])['person_id'],
              analysis: a,
            ),
          );
        }
      },
    ),
  ];
  List<Widget> more() => [
    const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonAvatar(staff: true, size: 64),
          SizedBox(height: 12),
          Text('합성 시연 담당자'),
          Text('계정과 기록은 서버 메모리에 저장됩니다.'),
        ],
      ),
    ),
    const SizedBox(height: 16),
    AppCard(
      onTap: () => openPage(context, const NotificationSettingsPage()),
      child: const ListTile(
        leading: Icon(Icons.notifications_outlined),
        title: Text('기기 푸시 알림 설정'),
        subtitle: Text('FCM 테스트 · 백엔드 자동 발송 미연결'),
      ),
    ),
    AppCard(
      onTap: () => openPage(context, const LiveTasksPage()),
      child: const ListTile(
        leading: Icon(Icons.checklist),
        title: Text('후속 업무'),
      ),
    ),
    AppCard(
      onTap: () => openPage(context, const AccessibilityPage()),
      child: const ListTile(
        leading: Icon(Icons.accessibility_new),
        title: Text('접근성 설정'),
      ),
    ),
    AppCard(
      onTap: () => openPage(context, const CallPage()),
      child: const ListTile(
        leading: Icon(Icons.call_outlined),
        title: Text('음성 상담'),
        subtitle: Text('통화 서버 연결 준비'),
      ),
    ),
    AppCard(
      onTap: () => openPage(context, RecordingLibraryPage(personId: selected)),
      child: const ListTile(
        leading: Icon(Icons.graphic_eq),
        title: Text('녹음 · 전사 보관함'),
        subtitle: Text('WAV 저장·재생·내보내기'),
      ),
    ),
    const SizedBox(height: 16),
    const InfoPanel(
      '현재 통합 서버에 없는 기능: 대상자·가족 로그인/연결, 자격 승인, 프로필·비밀번호 변경/찾기/탈퇴, 상담 가능 시간 설정, 예약 변경·불참, 인수인계, 영상·전화·채팅 통화. 화면 체험 모드에서만 확인할 수 있습니다.',
    ),
    const SizedBox(height: 16),
    AsyncActionButton(
      label: '로그아웃',
      secondary: true,
      action: CareScope.of(context).signOut,
    ),
  ];
}

class LiveTasksPage extends StatefulWidget {
  const LiveTasksPage({super.key});
  @override
  State<LiveTasksPage> createState() => _LiveTasksPageState();
}

class _LiveTasksPageState extends State<LiveTasksPage> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), r = app.repository as LiveCareRepository;
    selected ??= r.persons.firstOrNull?['person_id'];
    return AppPage(
      title: '후속 업무',
      child: PageBody(
        onRefresh: app.refresh,
        children: [
          if (selected != null) ...[
            DropdownButtonFormField<String>(
              initialValue: selected,
              isExpanded: true,
              items: [
                for (final p in r.persons)
                  DropdownMenuItem(
                    value: p['person_id'] as String,
                    child: Text(r.label(p['person_id'])),
                  ),
              ],
              onChanged: (v) => setState(() => selected = v),
              decoration: const InputDecoration(labelText: '대상자'),
            ),
            const SizedBox(height: 16),
            AsyncActionButton(
              label: '후속 업무 추가',
              action: () async {
                final text = await askText(context, '후속 업무', label: '합성 업무 제목');
                if (text == null || text.trim().isEmpty) return;
                await app.mutate((_) => r.addFollowup(selected!, text.trim()));
                if (mounted) setState(() {});
              },
            ),
          ] else
            const EmptyView(title: '대상자를 먼저 생성해 주세요'),
          for (final t in r.tasks.where((t) => t['person_id'] == selected)) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t['title']),
                  StatusBadge(
                    t['status'] == 'open'
                        ? '진행 전'
                        : t['status'] == 'completed'
                        ? '완료'
                        : '취소',
                  ),
                  if (t['status'] == 'open')
                    Wrap(
                      children: [
                        for (final action in ['complete', 'cancel'])
                          TextButton(
                            onPressed: () async {
                              await runCareTask(
                                context,
                                () =>
                                    app.mutate((_) => r.taskAction(t, action)),
                              );
                              if (mounted) setState(() {});
                            },
                            child: Text(
                              action == 'complete' ? '완료 처리' : '취소 처리',
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LiveNoticesPage extends StatefulWidget {
  const LiveNoticesPage({super.key});
  @override
  State<LiveNoticesPage> createState() => _LiveNoticesPageState();
}

class _LiveNoticesPageState extends State<LiveNoticesPage> {
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context), r = app.repository as LiveCareRepository;
    return AppPage(
      title: '인앱 알림',
      child: PageBody(
        onRefresh: app.refresh,
        children: [
          const InfoPanel('로그인한 본인에게 생성하는 수동 인앱 알림입니다. 자동 푸시·문자 발송과는 별도입니다.'),
          const SizedBox(height: 16),
          AsyncActionButton(
            label: '합성 인앱 알림 작성',
            action: () async {
              final text = await askText(context, '알림 작성', label: '합성 알림 내용');
              if (text == null || text.trim().isEmpty) return;
              await app.mutate((_) => r.createNotice('합성 후속 확인', text.trim()));
              if (mounted) setState(() {});
            },
          ),
          if (r.notices.isEmpty) const EmptyView(title: '새로운 알림이 없어요'),
          for (final n in r.notices.reversed) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n['title']),
                  const SizedBox(height: 8),
                  Text(n['body']),
                  StatusBadge(n['read_at'] == null ? '새 알림' : '읽음'),
                  if (n['read_at'] == null)
                    TextButton(
                      onPressed: () async {
                        await runCareTask(
                          context,
                          () => app.mutate(
                            (_) => r.markRead(n['notification_id']),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                      child: const Text('읽음 처리'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
