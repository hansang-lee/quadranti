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

    test('taskAt finds the nearest task within the radius', () {
      final tasks = [topRight, centre];
      expect(QuadrantPainter.taskAt(tasks, size, const Offset(105, 98))?.id, 'c');
      expect(QuadrantPainter.taskAt(tasks, size, const Offset(190, 5))?.id, 'tr');
      expect(QuadrantPainter.taskAt(tasks, size, const Offset(50, 50)), isNull);
    });
  });
}
