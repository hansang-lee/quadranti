import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/core/week.dart';

void main() {
  test('weekStartOf returns Monday for every day of the week', () {
    for (var d = 5; d <= 11; d++) {
      expect(weekStartOf(DateTime(2026, 10, d, 23, 59)), DateTime(2026, 10, 5));
    }
  });

  test('weekStartOf crosses month and year boundaries', () {
    expect(weekStartOf(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
  });

  test('addWeeks', () {
    expect(addWeeks(DateTime(2026, 10, 5), 1), DateTime(2026, 10, 12));
    expect(addWeeks(DateTime(2026, 10, 5), -2), DateTime(2026, 9, 21));
  });

  test('date key round trip', () {
    expect(formatDateKey(DateTime(2026, 3, 9)), '2026-03-09');
    expect(parseDateKey('2026-03-09'), DateTime(2026, 3, 9));
  });
}
