// One task from start to finish: add it with scores, watch it move quadrant
// in the editor, open it from the graph, tick it done, swipe it away and undo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/widgets/quadrant_painter.dart';

import 'support/scenario.dart';

void main() {
  ensureScenarioBinding();

  testWidgets('task lifecycle', (tester) async {
    final s = Scenario(tester, 'task_lifecycle');
    await s.launch(signedOut: true);
    await s.signUp();
    await s.closeGuide();

    // The editor's live card follows the sliders.
    await s.tap(find.byKey(const Key('addTask')));
    await s.enter(find.byKey(const Key('title')), '분기 보고서');
    await s.setSlider('효과', 9);
    await s.setSlider('착각', 8);
    await s.reveal(find.byKey(const Key('quadrantPreview')));
    expect(find.text('계획 (Q4)'), findsOneWidget);
    await s.shot('editor_plan');
    await s.tap(find.byKey(const Key('save')));
    await s.waitGone(find.byKey(const Key('save')));

    final task = s.tasks.weekTasks.single;
    expect(task.quadrant, Quadrant.plan);
    expect(task.effectiveness, 9);
    expect(task.illusion, 8);
    await s.shot('graph_one_task');

    // Tap the dot to edit it, and make it urgent again.
    final graph = tester.getRect(find.byKey(const Key('graph')));
    await tester.tapAt(graph.topLeft + QuadrantPainter.positionOf(task, graph.size));
    await s.settle();
    await s.waitFor(find.text('태스크 편집'), what: 'the editor opened from the graph');
    await s.setSlider('착각', 0);
    await s.reveal(find.byKey(const Key('quadrantPreview')));
    expect(find.text('집중 (Q1)'), findsOneWidget);
    await s.tap(find.byKey(const Key('save')));
    await s.waitGone(find.byKey(const Key('save')));
    expect(s.tasks.weekTasks.single.quadrant, Quadrant.focus);

    // Done, then swipe away and undo, in the list.
    await s.tap(find.text('목록'));
    await s.tap(find.byType(Checkbox));
    expect(s.tasks.weekTasks.single.done, isTrue);
    expect(find.text('완료 1/1'), findsOneWidget);
    await s.shot('list_done');

    await tester.drag(find.text('분기 보고서'), const Offset(-500, 0));
    await s.settle();
    expect(s.tasks.weekTasks, isEmpty);
    await s.shot('deleted');
    await s.tap(find.text('되돌리기'));
    expect(s.tasks.weekTasks.single.title, '분기 보고서');
    await s.shot('restored');
  });
}
