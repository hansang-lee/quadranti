/// Weeks run Monday to Sunday and are identified by their Monday, as a
/// local date with no time part.
DateTime weekStartOf(DateTime date) {
  return DateTime(date.year, date.month, date.day - (date.weekday - DateTime.monday));
}

/// Same week, `weeks` later (negative for earlier).
///
/// Dates here are built from calendar fields, never by adding a Duration,
/// so a daylight-saving shift cannot move them off midnight.
DateTime addWeeks(DateTime weekStart, int weeks) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + 7 * weeks);

/// `yyyy-MM-dd`, the storage form for dates.
String formatDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}
