import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/core/week.dart';
import 'package:quadranti/models/task_model.dart';

void main() {
  group('quadrant', () {
    Task t({double imm = 0, double eff = 0, double waste = 0, double ill = 0}) =>
        Task(id: 'x', title: 'x', immediacy: imm, effectiveness: eff, waste: waste, illusion: ill);

    test('each quadrant', () {
      expect(t(eff: 5, imm: 5).quadrant, Quadrant.focus);
      expect(t(waste: 5, imm: 5).quadrant, Quadrant.caution);
      expect(t(waste: 5, ill: 5).quadrant, Quadrant.eliminate);
      expect(t(eff: 5, ill: 5).quadrant, Quadrant.plan);
    });

    test('points on an axis go right / up', () {
      expect(t().quadrant, Quadrant.focus);
      expect(t(ill: 5).quadrant, Quadrant.plan);
      expect(t(waste: 5).quadrant, Quadrant.caution);
    });
  });

  test('scores are clamped to 0..10, NaN becomes 0', () {
    final task = Task(id: 'x', title: 'x', immediacy: 15, effectiveness: -3, waste: double.nan);
    expect(task.immediacy, 10);
    expect(task.effectiveness, 0);
    expect(task.waste, 0);
    expect(task.normalizedY, inInclusiveRange(0, 1));
    expect(task.normalizedX, inInclusiveRange(0, 1));
  });

  test('normalized corners', () {
    final topRight = Task(id: 'x', title: 'x', immediacy: 10, effectiveness: 10);
    expect(topRight.normalizedX, 1);
    expect(topRight.normalizedY, 1);
    final bottomLeft = Task(id: 'x', title: 'x', immediacy: 0, effectiveness: 0, waste: 10, illusion: 10);
    expect(bottomLeft.normalizedX, 0);
    expect(bottomLeft.normalizedY, 0);
  });

  test('weekStart is snapped to Monday', () {
    // 2026-10-07 is a Wednesday.
    final task = Task(id: 'x', title: 'x', weekStart: DateTime(2026, 10, 7, 15, 30));
    expect(task.weekStart, DateTime(2026, 10, 5));
  });

  test('toMap / fromMap round trip', () {
    final task = Task(
      id: 'a',
      title: '보고서',
      description: 'd',
      immediacy: 7,
      effectiveness: 8.5,
      waste: 1,
      illusion: 2,
      weekStart: DateTime(2026, 10, 5),
      done: true,
      createdAt: DateTime(2026, 10, 1, 9),
    );
    expect(Task.fromMap(task.toMap()), task);
  });

  test('fromMap fills defaults for missing keys', () {
    final task = Task.fromMap({'id': 'a', 'title': 't'});
    expect(task.immediacy, 5);
    expect(task.done, isFalse);
    expect(task.weekStart, weekStartOf(DateTime.now()));
  });

  test('copyWith keeps id and createdAt', () {
    final task = Task(id: 'a', title: 't', createdAt: DateTime(2026, 1, 1));
    final edited = task.copyWith(title: 'u', done: true);
    expect(edited.id, 'a');
    expect(edited.createdAt, DateTime(2026, 1, 1));
    expect(edited.title, 'u');
    expect(edited.done, isTrue);
  });
}
