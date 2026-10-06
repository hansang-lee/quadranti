import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/services/task_repository.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('quadranti_tasks_');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('tasks survive closing Hive and are kept per user', () async {
    final a = HiveTaskRepository('a');
    await a.put(Task(id: '1', title: 'one', createdAt: DateTime(2026, 1, 2)));
    await a.put(Task(id: '2', title: 'two', createdAt: DateTime(2026, 1, 1)));
    await a.delete('missing');
    await HiveTaskRepository('b').put(Task(id: '3', title: 'other'));
    await Hive.close();

    Hive.init(dir.path);
    final loaded = await HiveTaskRepository('a').loadAll();
    expect(loaded.map((t) => t.title), ['two', 'one']);

    await HiveTaskRepository('a').delete('1');
    expect((await HiveTaskRepository('a').loadAll()).map((t) => t.id), ['2']);
  });

  test('a damaged record is skipped, the rest still load', () async {
    final repo = HiveTaskRepository('a');
    await repo.put(Task(id: '1', title: 'good'));
    final box = await Hive.openBox('tasks_a');
    await box.put('2', {'id': '2', 'title': 'bad', 'done': 'yes'});

    expect((await repo.loadAll()).map((t) => t.id), ['1']);
    expect(box.containsKey('2'), isTrue);
  });
}
