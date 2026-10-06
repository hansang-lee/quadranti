import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/widgets/quadrant_painter.dart';

void main() {
  test('painter repaints after a task is added', () {
    final provider = TaskProvider();
    final before = QuadrantPainter(tasks: provider.tasks);

    provider.addTask(Task(id: 'a', title: 'A'));
    final after = QuadrantPainter(tasks: provider.tasks);

    expect(after.shouldRepaint(before), isTrue);
  });

  test('painter does not repaint when nothing changed', () {
    final provider = TaskProvider()..addTask(Task(id: 'a', title: 'A'));
    final first = QuadrantPainter(tasks: provider.tasks);
    final second = QuadrantPainter(tasks: provider.tasks);

    expect(second.shouldRepaint(first), isFalse);
  });

  test('exposed task list cannot be mutated from outside', () {
    final provider = TaskProvider();
    expect(() => provider.tasks.add(Task(id: 'x', title: 'X')), throwsUnsupportedError);
  });
}
