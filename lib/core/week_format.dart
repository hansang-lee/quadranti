import 'week.dart';

/// "10월 5일 – 11일", or "9월 28일 – 10월 4일" across months; the year is
/// added when the week is not in the current year.
String formatWeekRange(DateTime weekStart, {DateTime? now}) {
  final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
  final year = weekStart.year != (now ?? DateTime.now()).year ? '${weekStart.year}년 ' : '';
  final endText = end.month == weekStart.month ? '${end.day}일' : '${end.month}월 ${end.day}일';
  return '$year${weekStart.month}월 ${weekStart.day}일 – $endText';
}

/// "이번 주", "다음 주", "지난 주", or null for any other week.
String? relativeWeekName(DateTime weekStart, {DateTime? now}) {
  final current = weekStartOf(now ?? DateTime.now());
  if (weekStart == current) return '이번 주';
  if (weekStart == addWeeks(current, 1)) return '다음 주';
  if (weekStart == addWeeks(current, -1)) return '지난 주';
  return null;
}
