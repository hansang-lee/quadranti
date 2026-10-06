import 'package:hive_ce/hive_ce.dart';
import '../models/task_model.dart';

/// Storage for one user's tasks.
abstract class TaskRepository {
  Future<List<Task>> loadAll();
  Future<void> put(Task task);
  Future<void> delete(String id);
}

/// One Hive box per user (`tasks_<userId>`), tasks stored as maps keyed by id.
class HiveTaskRepository implements TaskRepository {
  HiveTaskRepository(this.userId);

  final String userId;

  Future<Box> _open() => Hive.openBox('tasks_$userId');

  @override
  Future<List<Task>> loadAll() async {
    final box = await _open();
    final tasks = box.values.map((v) => Task.fromMap(v as Map)).toList();
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

  @override
  Future<List<Task>> loadAll() async =>
      _tasks.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> put(Task task) async => _tasks[task.id] = task;

  @override
  Future<void> delete(String id) async => _tasks.remove(id);
}
