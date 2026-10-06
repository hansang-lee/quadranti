import 'dart:convert';
import '../models/task_model.dart';

/// JSON backup of a user's tasks:
/// `{"app": "quadranti", "version": 1, "exportedAt": "...", "tasks": [Task.toMap, ...]}`.
class TaskBackup {
  static const int version = 1;

  static String encode(List<Task> tasks, {DateTime? now}) => const JsonEncoder.withIndent(' ').convert({
        'app': 'quadranti',
        'version': version,
        'exportedAt': (now ?? DateTime.now()).toIso8601String(),
        'tasks': [for (final t in tasks) t.toMap()],
      });

  /// Parses a backup. A task id listed twice keeps its last entry. Throws
  /// [FormatException] with a Korean message that can be shown to the user
  /// as is.
  static List<Task> decode(String text) {
    final Object? data;
    try {
      data = jsonDecode(text.trim());
    } on FormatException {
      throw const FormatException('백업 형식이 아닙니다 (JSON 아님)');
    }
    if (data is! Map || data['app'] != 'quadranti' || data['tasks'] is! List) {
      throw const FormatException('Quadranti 백업이 아닙니다');
    }
    final v = data['version'];
    if (v is! int || v > version) {
      throw const FormatException('더 새로운 버전의 앱에서 만든 백업입니다');
    }
    final tasks = <String, Task>{};
    for (final item in data['tasks'] as List) {
      if (item is! Map || item['id'] is! String || (item['id'] as String).isEmpty) {
        throw const FormatException('백업에 잘못된 태스크가 있습니다');
      }
      try {
        final task = Task.fromMap(item);
        tasks[task.id] = task;
      } catch (_) {
        throw const FormatException('백업에 잘못된 태스크가 있습니다');
      }
    }
    return tasks.values.toList();
  }
}
