import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/services/task_repository.dart';

void main() {
  // Wednesday; the week starts Monday 2026-10-05.
  final now = DateTime(2026, 10, 7);
  late Map<String, MemoryTaskRepository> repos;
  late TaskProvider provider;

  setUp(() async {
    repos = {};
    provider = TaskProvider(
      repositoryFor: (id) => repos.putIfAbsent(id, MemoryTaskRepository.new),
      now: now,
    );
    await provider.setUser('u1');
  });

  Task task(String id, {DateTime? week, bool done = false}) =>
      Task(id: id, title: id, weekStart: week ?? now, done: done);

  test('sample data covers all four quadrants', () async {
    await provider.loadSampleData();
    expect(provider.tasks.map((t) => t.quadrant).toSet(), Quadrant.values.toSet());
  });

  test('changes are written to the user repository and reload', () async {
    await provider.addTask(task('a'));
    await provider.addTask(task('b'));
    await provider.updateTask(provider.byId('a')!.copyWith(title: 'A'));
    await provider.removeTask('b');

    final fresh = TaskProvider(repositoryFor: (id) => repos[id]!, now: now);
    await fresh.setUser('u1');
    expect(fresh.tasks.map((t) => t.title), ['A']);
  });

  test('users do not see each other\'s tasks', () async {
    await provider.addTask(task('a'));
    await provider.setUser('u2');
    expect(provider.tasks, isEmpty);
    await provider.setUser('u1');
    expect(provider.tasks.map((t) => t.id), ['a']);
  });

  test('signing out clears tasks and stops writing', () async {
    await provider.setUser(null);
    expect(provider.tasks, isEmpty);
    await provider.addTask(task('a'));
    expect(await repos['u1']!.loadAll(), isEmpty);
  });

  test('a slow load for a previous user is discarded', () async {
    final slow = _SlowRepository([task('old')]);
    final p = TaskProvider(repositoryFor: (id) => id == 'slow' ? slow : MemoryTaskRepository(), now: now);
    final first = p.setUser('slow');
    await p.setUser('fast');
    slow.release();
    await first;
    expect(p.userId, 'fast');
    expect(p.tasks, isEmpty);
  });

  test('weekTasks and week navigation', () async {
    await provider.addTask(task('this'));
    await provider.addTask(task('next', week: DateTime(2026, 10, 12)));
    expect(provider.weekTasks.map((t) => t.id), ['this']);

    provider.shiftWeek(1);
    expect(provider.selectedWeek, DateTime(2026, 10, 12));
    expect(provider.weekTasks.map((t) => t.id), ['next']);
  });

  test('weekTasks keeps its identity until something changes', () async {
    await provider.addTask(task('a'));
    final first = provider.weekTasks;
    expect(identical(provider.weekTasks, first), isTrue);
    await provider.toggleDone('a');
    expect(identical(provider.weekTasks, first), isFalse);
  });

  test('toggleDone flips done', () async {
    await provider.addTask(task('a'));
    await provider.toggleDone('a');
    expect(provider.byId('a')!.done, isTrue);
  });

  test('carryOverUnfinished from an explicit week', () async {
    final last = DateTime(2026, 9, 28);
    await provider.addTask(task('old', week: last));
    expect(provider.unfinishedIn(last), hasLength(1));
    expect(await provider.carryOverUnfinished(from: last, to: provider.selectedWeek), 1);
    expect(provider.weekTasks.map((t) => t.id), ['old']);
    expect(provider.unfinishedIn(last), isEmpty);
  });

  test('carryOverUnfinished moves only open tasks to next week', () async {
    await provider.addTask(task('open'));
    await provider.addTask(task('done', done: true));
    expect(await provider.carryOverUnfinished(), 1);
    expect(provider.byId('open')!.weekStart, DateTime(2026, 10, 12));
    expect(provider.byId('done')!.weekStart, DateTime(2026, 10, 5));
  });
}

class _SlowRepository extends MemoryTaskRepository {
  _SlowRepository(this._result);
  final List<Task> _result;
  final _released = Completer<void>();

  void release() => _released.complete();

  @override
  Future<List<Task>> loadAll() async {
    await _released.future;
    return _result;
  }
}
