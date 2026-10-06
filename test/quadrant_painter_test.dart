import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/services/task_repository.dart';
import 'package:quadranti/widgets/quadrant_painter.dart';

void main() {
  Future<TaskProvider> provider() async {
    final p = TaskProvider(repositoryFor: (_) => MemoryTaskRepository());
    await p.setUser('u');
    return p;
  }

  test('painter repaints after a task is added', () async {
    final p = await provider();
    final before = QuadrantPainter(tasks: p.weekTasks);

    await p.addTask(Task(id: 'a', title: 'A'));
    final after = QuadrantPainter(tasks: p.weekTasks);

    expect(after.shouldRepaint(before), isTrue);
  });

  test('painter does not repaint when nothing changed', () async {
    final p = await provider();
    await p.addTask(Task(id: 'a', title: 'A'));
    final first = QuadrantPainter(tasks: p.weekTasks);
    final second = QuadrantPainter(tasks: p.weekTasks);

    expect(second.shouldRepaint(first), isFalse);
  });

  test('exposed task list cannot be mutated from outside', () async {
    final p = await provider();
    expect(() => p.tasks.add(Task(id: 'x', title: 'X')), throwsUnsupportedError);
  });

  group('positions and taps', () {
    const size = Size(200, 200);
    final topRight = Task(id: 'tr', title: 'tr', immediacy: 10, effectiveness: 10);
    final centre = Task(id: 'c', title: 'c', immediacy: 0, effectiveness: 0);

    test('positionOf maps scores to canvas with y flipped', () {
      expect(QuadrantPainter.positionOf(topRight, size), const Offset(200, 0));
      expect(QuadrantPainter.positionOf(centre, size), const Offset(100, 100));
    });

    test('tasksAt finds the nearest point within the radius', () {
      final tasks = [topRight, centre];
      expect(QuadrantPainter.tasksAt(tasks, size, const Offset(105, 98)).map((t) => t.id), ['c']);
      expect(QuadrantPainter.tasksAt(tasks, size, const Offset(190, 5)).map((t) => t.id), ['tr']);
      expect(QuadrantPainter.tasksAt(tasks, size, const Offset(50, 50)), isEmpty);
    });

    test('tasks with the same scores share a point', () {
      final twin = Task(id: 'tw', title: 'tw', immediacy: 10, effectiveness: 10);
      final tasks = [topRight, centre, twin];
      expect(
        QuadrantPainter.groupByPosition(tasks).map((g) => g.map((t) => t.id).toList()),
        [['tr', 'tw'], ['c']],
      );
      expect(QuadrantPainter.tasksAt(tasks, size, const Offset(199, 1)).map((t) => t.id), ['tr', 'tw']);
    });
  });

  test('semantic label names tasks, quadrant and position', () {
    final a = Task(id: 'a', title: '보고서', immediacy: 7, effectiveness: 9, waste: 1, illusion: 2);
    final b = Task(id: 'b', title: '메일', immediacy: 7, effectiveness: 9, waste: 1, illusion: 2, done: true);
    expect(QuadrantPainter.semanticLabel([a, b]), '보고서, 메일 (완료). 집중 사분면, 가치 +8, 실제 긴급도 +5');
  });
}
