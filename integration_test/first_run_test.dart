// A new user: sign up, read the guide, find an empty week, load the samples
// and see one task in each quadrant on the graph and in the list.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/models/task_model.dart';

import 'support/scenario.dart';

void main() {
  ensureScenarioBinding();

  testWidgets('first run', (tester) async {
    final s = Scenario(tester, 'first_run');
    await s.launch(signedOut: true);
    await s.shot('login');

    await s.signUp();
    await s.shot('guide');
    await s.closeGuide();

    expect(find.text('이 주에 등록된 태스크가 없습니다'), findsOneWidget);
    expect(find.text('이번 주'), findsOneWidget);
    await s.shot('empty_week');

    await s.tap(find.byKey(const Key('loadSamples')));
    expect(s.tasks.weekTasks.map((t) => t.quadrant).toSet(), Quadrant.values.toSet());
    expect(find.text('완료 0/4'), findsOneWidget);
    await s.shot('graph');

    await s.tap(find.text('목록'));
    for (final title in ['핵심 프로젝트 마감', '형식적인 회의', '장기 전략 정리', '무한 스크롤']) {
      expect(find.text(title), findsOneWidget);
    }
    await s.shot('list');
  });
}
