// What is saved survives a restart of the app, and stays with its owner:
// another account on the same device sees none of it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scenario.dart';

void main() {
  ensureScenarioBinding();

  testWidgets('persistence', (tester) async {
    final s = Scenario(tester, 'persistence');
    await s.launch(signedOut: true);
    await s.signUp();
    await s.closeGuide();
    await s.addTask('남는 태스크', effectiveness: 7, immediacy: 3, illusion: 6);
    await s.tap(find.text('목록'));
    await s.tap(find.byType(Checkbox));

    // A cold start keeps the session and the task, done mark included.
    await s.launch();
    await s.waitFor(find.byKey(const Key('addTask')), what: 'home without signing in again');
    await s.tap(find.text('목록'));
    expect(find.text('남는 태스크'), findsOneWidget);
    final kept = s.tasks.weekTasks.single;
    expect(kept.done, isTrue);
    expect((kept.effectiveness, kept.immediacy, kept.illusion), (7.0, 3.0, 6.0));
    await s.shot('after_restart');

    // Someone else on this device starts empty.
    await s.menu('로그아웃 (테스터)');
    final other = Scenario(tester, 'persistence_other')..now = s.now;
    await other.signUp(displayName: '다른 사람');
    await other.closeGuide();
    expect(other.tasks.tasks, isEmpty);
    await other.shot('other_account_empty');

    // And the first account still has its task after signing back in.
    await other.menu('로그아웃 (다른 사람)');
    await s.signIn();
    await s.tap(find.text('목록'));
    expect(find.text('남는 태스크'), findsOneWidget);
    await s.shot('back_to_first');
  });
}
