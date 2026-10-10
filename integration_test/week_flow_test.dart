// Weeks: step to next week and back, and when a new week starts, bring the
// unfinished tasks of the last one along from the banner.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scenario.dart';

void main() {
  ensureScenarioBinding();

  testWidgets('week flow', (tester) async {
    final s = Scenario(tester, 'week_flow');
    await s.launch(signedOut: true);
    await s.signUp();
    await s.closeGuide();
    await s.addTask('끝낼 일');
    await s.addTask('못 끝낸 일');
    await s.tap(find.text('목록'));
    await s.tap(find.descendant(of: find.widgetWithText(ListTile, '끝낼 일'), matching: find.byType(Checkbox)));

    // Next week is empty; the title says so and tapping it comes back.
    await s.tap(find.byKey(const Key('nextWeek')));
    expect(find.text('다음 주'), findsOneWidget);
    expect(find.text('이 주에 등록된 태스크가 없습니다'), findsOneWidget);
    await s.tap(find.byKey(const Key('weekTitle')));
    expect(find.text('이번 주'), findsOneWidget);

    // A week later: the banner offers last week's one open task.
    await s.advance(const Duration(days: 7));
    expect(find.text('이번 주'), findsOneWidget);
    expect(find.text('지난 주에 끝내지 못한 태스크가 1개 있어요'), findsOneWidget);
    await s.shot('banner');
    await s.tap(find.byKey(const Key('carryOverAccept')));
    expect(s.tasks.weekTasks.map((t) => t.title), ['못 끝낸 일']);
    expect(find.byKey(const Key('carryOverBanner')), findsNothing);
    await s.shot('carried_over');
  });
}
