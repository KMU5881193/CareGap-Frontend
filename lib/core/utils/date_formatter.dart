abstract final class CareDate {
  static String date(DateTime value) =>
      '${value.year}년 ${value.month}월 ${value.day}일';
  static String short(DateTime value) => '${value.month}월 ${value.day}일';
  static String time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  static String full(DateTime value) => '${date(value)} ${time(value)}';
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
