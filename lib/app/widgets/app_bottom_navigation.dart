import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFE2E9E4))),
    ),
    child: NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: '일정',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: '기록',
        ),
        NavigationDestination(
          icon: Icon(Icons.volunteer_activism_outlined),
          selectedIcon: Icon(Icons.volunteer_activism),
          label: '복지정보',
        ),
        NavigationDestination(icon: Icon(Icons.more_horiz), label: '더보기'),
      ],
    ),
  );
}
