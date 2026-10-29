import 'package:flutter/material.dart';

import '../../../../app/care_scope.dart';
import '../../../../app/widgets/app_widgets.dart';
import '../../../appointments/presentation/pages/calendar_page.dart';
import '../../../records/presentation/pages/records_page.dart';
import '../../../welfare/presentation/pages/welfare_list_page.dart';
import '../../../settings/presentation/pages/more_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import 'beneficiary_home_page.dart';
import 'staff_home_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});
  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final app = CareScope.of(context);
    const titles = ['돌봄틈새 AI', '상담 일정', '상담 기록', '복지 정보', '더보기'];
    final pages = [
      app.isStaff ? const StaffHomePage() : const BeneficiaryHomePage(),
      const CalendarPage(),
      const RecordsPage(),
      const WelfareListPage(),
      const MorePage(),
    ];
    final unread = app.data?.notices.where((n) => !n.read).length ?? 0;
    return AppPage(
      title: titles[index],
      titleWidget: index == 0 || index == 2 ? const AppBrand(size: 30) : null,
      actions: [
        IconButton(
          tooltip: '알림 $unread개 읽지 않음',
          onPressed: app.data == null
              ? null
              : () => openPage(context, const NotificationsPage()),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: index,
        onSelected: (value) => setState(() => index = value),
      ),
      child: IndexedStack(index: index, children: pages),
    );
  }
}
