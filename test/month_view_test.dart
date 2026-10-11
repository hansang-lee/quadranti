import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/screens/month_view.dart';

void main() {
  test('weeksOfMonth: every Monday whose week touches the month', () {
    // October 2026 starts on a Thursday and ends on a Saturday.
    expect(weeksOfMonth(DateTime(2026, 10)), [
      DateTime(2026, 9, 28),
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
    ]);
    // February 2027 starts on a Monday: exactly four weeks.
    expect(weeksOfMonth(DateTime(2027, 2)), hasLength(4));
  });

  test('monthOfWeek: a split week goes to the month of its Thursday', () {
    expect(monthOfWeek(DateTime(2026, 9, 28)), DateTime(2026, 10)); // Thu 1 Oct
    expect(monthOfWeek(DateTime(2026, 8, 31)), DateTime(2026, 9)); // Thu 3 Sep
    expect(monthOfWeek(DateTime(2026, 12, 28)), DateTime(2026, 12)); // Thu 31 Dec
  });

  test('formatMonth', () {
    expect(formatMonth(DateTime(2026, 10)), '2026년 10월');
  });
}
