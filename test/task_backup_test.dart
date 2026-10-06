import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/models/repeat_rule.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/services/task_backup.dart';
import 'package:quadranti/services/task_repository.dart';

void main() {
  final a = Task(id: 'a', title: '가', immediacy: 7, weekStart: DateTime(2026, 10, 5), createdAt: DateTime(2026, 10, 1));
  final b = Task(id: 'b', title: '나', done: true, weekStart: DateTime(2026, 10, 12), createdAt: DateTime(2026, 10, 2));

  test('round trip', () {
    final rule = RepeatRule.fromTask(a.copyWith(seriesId: 'a'));
    final decoded = TaskBackup.decode(TaskBackup.encode([a, b], rules: [rule]));
    expect(decoded.tasks, [a, b]);
    expect(decoded.rules, [rule]);
  });

  test('a duplicated id keeps its last entry', () {
    final text = TaskBackup.encode([a, a.copyWith(title: 'later')]);
    expect(TaskBackup.decode(text).tasks.map((t) => t.title), ['later']);
  });

  test('version 1 backups (no repeats) still load', () {
    final v1 = '{"app": "quadranti", "version": 1, "tasks": [{"id": "x", "title": "old"}]}';
    final decoded = TaskBackup.decode(v1);
    expect(decoded.tasks.single.title, 'old');
    expect(decoded.rules, isEmpty);
  });

  test('rejects bad input with a user-facing message', () {
    void rejects(String text, String message) => expect(
          () => TaskBackup.decode(text),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', message)),
        );
    rejects('not json', '백업 형식이 아닙니다 (JSON 아님)');
    rejects('[]', 'Quadranti 백업이 아닙니다');
    rejects('{"app": "other", "version": 1, "tasks": []}', 'Quadranti 백업이 아닙니다');
    rejects('{"app": "quadranti", "version": 99, "tasks": []}', '더 새로운 버전의 앱에서 만든 백업입니다');
    rejects('{"app": "quadranti", "version": 1, "tasks": [{"title": "no id"}]}', '백업에 잘못된 태스크가 있습니다');
    rejects('{"app": "quadranti", "version": 1, "tasks": [{"id": "x", "immediacy": "high"}]}', '백업에 잘못된 태스크가 있습니다');
    rejects('{"app": "quadranti", "version": 2, "tasks": [], "repeats": [{"id": "r"}]}', '백업에 잘못된 반복 규칙이 있습니다');
  });

  test('import merges by id and persists', () async {
    final repo = MemoryTaskRepository();
    final provider = TaskProvider(repositoryFor: (_) => repo);
    await provider.setUser('u');
    await provider.addTask(a);
    await provider.addTask(Task(id: 'keep', title: 'keep'));

    final result = await provider.importTasks([a.copyWith(title: '가2'), b]);
    expect(result.added, 1);
    expect(result.replaced, 1);
    expect(provider.tasks.map((t) => t.id).toSet(), {'a', 'keep', 'b'});
    expect(provider.byId('a')!.title, '가2');
    expect((await repo.loadAll()).map((t) => t.id).toSet(), {'a', 'keep', 'b'});
  });
}
