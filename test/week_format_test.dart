import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/core/week_format.dart';

void main() {
  final now = DateTime(2026, 10, 7);

  test('range within one month', () {
    expect(formatWeekRange(DateTime(2026, 10, 5), now: now), '10월 5일 – 11일');
  });

  test('range across months', () {
    expect(formatWeekRange(DateTime(2026, 9, 28), now: now), '9월 28일 – 10월 4일');
  });

  test('other years show the year', () {
    expect(formatWeekRange(DateTime(2027, 1, 4), now: now), '2027년 1월 4일 – 10일');
  });

  test('relative names', () {
    expect(relativeWeekName(DateTime(2026, 10, 5), now: now), '이번 주');
    expect(relativeWeekName(DateTime(2026, 10, 12), now: now), '다음 주');
    expect(relativeWeekName(DateTime(2026, 9, 28), now: now), '지난 주');
    expect(relativeWeekName(DateTime(2026, 10, 19), now: now), isNull);
  });
}
