import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/core/week.dart';
import 'package:quadranti/models/repeat_rule.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/services/task_repository.dart';

void main() {
  // Wednesday 2026-10-07; this week starts Monday 2026-10-05.
  var now = DateTime(2026, 10, 7);
  final week0 = DateTime(2026, 10, 5);
  final week1 = DateTime(2026, 10, 12);
  final week3 = DateTime(2026, 10, 26);
  late MemoryTaskRepository repo;
  late TaskProvider provider;

  Future<TaskProvider> open() async {
    final p = TaskProvider(repositoryFor: (_) => repo, clock: () => now);
    await p.setUser('u');
    return p;
  }

  setUp(() async {
    now = DateTime(2026, 10, 7);
    repo = MemoryTaskRepository();
    provider = await open();
  });

  Future<Task> repeating(String id, {DateTime? week}) async {
    final t = Task(id: id, title: id, weekStart: week ?? week0, effectiveness: 8);
    await provider.addTask(t);
    await provider.setRepeat(t, true);
    return provider.byId(id)!;
  }

  test('turning repeat on makes a series and a rule, nothing new this week', () async {
    final t = await repeating('gym');
    expect(t.seriesId, 'gym');
    expect(provider.isRepeating(t), isTrue);
    expect(provider.rules.single.lastWeek, week0);
    expect(provider.tasks, hasLength(1));
  });

  test('next week gets one instance, on load and only once', () async {
    await repeating('gym');
    now = DateTime(2026, 10, 13);
    final reopened = await open();
    await reopened.createDueRepeats();
    final inWeek1 = reopened.tasks.where((t) => t.weekStart == week1).toList();
    expect(inWeek1.map((t) => t.id), [RepeatRule.instanceId('gym', week1)]);
    expect(inWeek1.single.done, isFalse);
    expect(inWeek1.single.effectiveness, 8);
    expect((await repo.loadAll()).length, 2);
    expect((await repo.loadRules()).single.lastWeek, week1);
  });

  test('missed weeks are not back-filled', () async {
    await repeating('gym');
    now = DateTime(2026, 10, 28);
    final reopened = await open();
    expect(reopened.tasks.map((t) => t.weekStart).toSet(), {week0, week3});
  });

  test('an app left open into a new week catches up on the next week change', () async {
    await repeating('gym');
    now = DateTime(2026, 10, 13);
    provider.selectWeek(now);
    await pumpEventQueue();
    expect(provider.weekTasks.map((t) => t.seriesId), ['gym']);
  });

  test('editing an instance updates the template for later weeks', () async {
    final t = await repeating('gym');
    await provider.updateTask(t.copyWith(title: '헬스', waste: 3));
    now = DateTime(2026, 10, 13);
    await provider.createDueRepeats();
    final next = provider.tasks.firstWhere((t) => t.weekStart == week1);
    expect(next.title, '헬스');
    expect(next.waste, 3);
  });

  test('turning repeat off stops new instances and keeps old ones', () async {
    final t = await repeating('gym');
    await provider.setRepeat(t, false);
    expect(provider.isRepeating(t), isFalse);
    expect(await repo.loadRules(), isEmpty);
    now = DateTime(2026, 10, 13);
    await provider.createDueRepeats();
    expect(provider.tasks.map((t) => t.id), ['gym']);
  });

  test('deleting this week\'s instance does not bring it back', () async {
    await repeating('gym');
    now = DateTime(2026, 10, 13);
    await provider.createDueRepeats();
    await provider.removeTask(RepeatRule.instanceId('gym', week1));
    await provider.createDueRepeats();
    final reopened = await open();
    expect(reopened.tasks.where((t) => t.weekStart == week1), isEmpty);
  });

  test('a task made to repeat in a past week starts from the current week', () async {
    final lastWeek = addWeeks(week0, -1);
    await repeating('old', week: lastWeek);
    expect(provider.tasks.where((t) => t.weekStart == week0).map((t) => t.seriesId), ['old']);
  });

  test('carry-over leaves a repeating task behind when its series is already there', () async {
    await repeating('gym');
    await provider.addTask(Task(id: 'plain', title: 'plain', weekStart: week0));
    now = DateTime(2026, 10, 13);
    await provider.createDueRepeats();

    expect(provider.carryOverCandidates(week0, week1).map((t) => t.id), ['plain']);
    expect(await provider.carryOverUnfinished(from: week0, to: week1), 1);
    expect(provider.byId('gym')!.weekStart, week0);
  });

  test('importing rules keeps the later lastWeek so no week is made twice', () async {
    await repeating('gym');
    now = DateTime(2026, 10, 13);
    await provider.createDueRepeats();
    final older = RepeatRule(id: 'gym', title: 'gym', lastWeek: week0);
    await provider.importTasks(const [], rules: [older]);
    expect(provider.rules.single.lastWeek, week1);
    expect(provider.tasks.where((t) => t.weekStart == week1), hasLength(1));
  });

  test('instance ids are deterministic per rule and week', () {
    expect(RepeatRule.instanceId('gym', week1), 'gym-2026-10-12');
  });
}
