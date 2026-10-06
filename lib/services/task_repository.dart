import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import '../models/repeat_rule.dart';
import '../models/task_model.dart';

/// Storage for one user's tasks and repeat rules.
abstract class TaskRepository {
  Future<List<Task>> loadAll();
  Future<void> put(Task task);
  Future<void> delete(String id);

  Future<List<RepeatRule>> loadRules();
  Future<void> putRule(RepeatRule rule);
  Future<void> deleteRule(String id);
}

/// Two Hive boxes per user, `tasks_<userId>` and `repeats_<userId>`, with
/// records stored as maps keyed by id.
class HiveTaskRepository implements TaskRepository {
  HiveTaskRepository(this.userId);

  final String userId;

  Future<Box> _open() => Hive.openBox('tasks_$userId');
  Future<Box> _openRules() => Hive.openBox('repeats_$userId');

  @override
  Future<List<RepeatRule>> loadRules() async {
    final box = await _openRules();
    final rules = <RepeatRule>[];
    for (final key in box.keys) {
      try {
        rules.add(RepeatRule.fromMap(box.get(key) as Map));
      } catch (e) {
        debugPrint('Skipping unreadable repeat rule $key in ${box.name}: $e');
      }
    }
    return rules;
  }

  @override
  Future<void> putRule(RepeatRule rule) async => (await _openRules()).put(rule.id, rule.toMap());

  @override
  Future<void> deleteRule(String id) async => (await _openRules()).delete(id);

  @override
  Future<List<Task>> loadAll() async {
    final box = await _open();
    final tasks = <Task>[];
    for (final key in box.keys) {
      try {
        tasks.add(Task.fromMap(box.get(key) as Map));
      } catch (e) {
        // One damaged record must not hide all the others. It stays in the
        // box untouched, so it can still be inspected or repaired.
        debugPrint('Skipping unreadable task $key in ${box.name}: $e');
      }
    }
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  @override
  Future<void> put(Task task) async {
    final box = await _open();
    await box.put(task.id, task.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _open();
    await box.delete(id);
  }
}

/// In-memory repository for tests and for running without a signed-in user.
class MemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};
  final Map<String, RepeatRule> _rules = {};

  @override
  Future<List<RepeatRule>> loadRules() async => _rules.values.toList();

  @override
  Future<void> putRule(RepeatRule rule) async => _rules[rule.id] = rule;

  @override
  Future<void> deleteRule(String id) async => _rules.remove(id);

  @override
  Future<List<Task>> loadAll() async =>
      _tasks.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> put(Task task) async => _tasks[task.id] = task;

  @override
  Future<void> delete(String id) async => _tasks.remove(id);
}
