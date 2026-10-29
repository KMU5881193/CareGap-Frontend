import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';

class AppCalendar extends StatefulWidget {
  const AppCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.markedDates = const [],
  });
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final List<DateTime> markedDates;
  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  late DateTime focused = widget.selected;
  @override
  void didUpdateWidget(covariant AppCalendar old) {
    super.didUpdateWidget(old);
    if (!isSameDay(old.selected, widget.selected)) focused = widget.selected;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final width = math.max(
        constraints.maxWidth,
        math.max(294.0, 7 * (28 * scale + 12)),
      );
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: TableCalendar<DateTime>(
            locale: 'ko_KR',
            firstDay: DateTime(1900),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: focused,
            selectedDayPredicate: (d) => isSameDay(d, widget.selected),
            startingDayOfWeek: StartingDayOfWeek.sunday,
            availableCalendarFormats: const {CalendarFormat.month: '월'},
            rowHeight: math.max(48, 36 * scale),
            daysOfWeekHeight: math.max(30, 24 * scale),
            onDaySelected: (selected, focus) {
              setState(() => focused = focus);
              widget.onSelect(selected);
            },
            onPageChanged: (value) => focused = value,
            onHeaderTapped: (_) async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: focused,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100, 12, 31),
                initialDatePickerMode: DatePickerMode.year,
                helpText: '연도와 날짜 선택',
              );
              if (chosen != null && mounted) {
                setState(() => focused = chosen);
                widget.onSelect(chosen);
              }
            },
            pageAnimationDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 240),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                semanticLabel: '지난달',
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                semanticLabel: '다음 달',
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              weekendStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(5),
              defaultTextStyle: const TextStyle(fontSize: 14),
              weekendTextStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.danger,
              ),
              outsideTextStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFFABB4BE),
              ),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary),
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 14,
              ),
              selectedDecoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF339D7B), AppColors.primaryDark],
                ),
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              markerDecoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF62B58C),
              ),
              markersMaxCount: 3,
              markerSize: 4,
              markerMargin: const EdgeInsets.symmetric(horizontal: 1),
            ),
            eventLoader: (day) =>
                widget.markedDates.where((d) => isSameDay(d, day)).toList(),
          ),
        ),
      );
    },
  );
}

Future<DateTime?> pickCareDate(BuildContext context, DateTime initial) =>
    showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DateSheet(initial: initial),
    );

class _DateSheet extends StatefulWidget {
  const _DateSheet({required this.initial});
  final DateTime initial;
  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late DateTime selected = widget.initial;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCalendar(
            selected: selected,
            onSelect: (d) => setState(() => selected = d),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: '날짜 선택',
            onPressed: () => Navigator.pop(context, selected),
          ),
        ],
      ),
    ),
  );
}
