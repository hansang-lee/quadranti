// A weekly task: it comes back by itself when the next week starts, and
// stops coming back once 매주 반복 is turned off.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scenario.dart';

void main() {
  ensureScenarioBinding();

  testWidgets('repeat', (tester) async {
    final s = Scenario(tester, 'repeat');
    await s.launch(signedOut: true);
    await s.signUp();
    await s.closeGuide();
    await s.addTask('주간 회고', effectiveness: 8, repeat: true);
    await s.tap(find.text('목록'));
    expect(find.text('매주'), findsOneWidget);
    await s.shot('repeating');

    // Next calendar week, after a cold start: a fresh, open copy.
    s.now = s.now.add(const Duration(days: 7));
    await s.launch();
    await s.waitFor(find.byKey(const Key('addTask')));
    await s.tap(find.text('목록'));
    final copy = s.tasks.weekTasks.single;
    expect(copy.title, '주간 회고');
    expect(copy.done, isFalse);
    expect(copy.effectiveness, 8);
    await s.shot('next_week_copy');

    // Stop it; the week after has nothing new.
    await s.tap(find.text('주간 회고'));
    await s.reveal(find.byKey(const Key('repeat')));
    await s.tap(find.byKey(const Key('repeat')));
    await s.tap(find.byKey(const Key('save')));
    await s.advance(const Duration(days: 7));
    expect(s.tasks.weekTasks, isEmpty);
    await s.shot('stopped');
  });
}
