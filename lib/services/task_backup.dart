import 'dart:convert';
import '../models/repeat_rule.dart';
import '../models/task_model.dart';

/// What a backup holds.
typedef BackupContents = ({List<Task> tasks, List<RepeatRule> rules});

/// JSON backup of a user's tasks and repeat rules:
/// `{"app": "quadranti", "version": 2, "exportedAt": "...",
///   "tasks": [Task.toMap, ...], "repeats": [RepeatRule.toMap, ...]}`.
/// Version 1 had no "repeats" and is still read.
class TaskBackup {
  static const int version = 2;

  static String encode(List<Task> tasks, {List<RepeatRule> rules = const [], DateTime? now}) =>
      const JsonEncoder.withIndent(' ').convert({
        'app': 'quadranti',
        'version': version,
        'exportedAt': (now ?? DateTime.now()).toIso8601String(),
        'tasks': [for (final t in tasks) t.toMap()],
        'repeats': [for (final r in rules) r.toMap()],
      });

  /// Parses a backup. An id listed twice keeps its last entry. Throws
  /// [FormatException] with a Korean message that can be shown to the user
  /// as is.
  static BackupContents decode(String text) {
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
    final repeats = data['repeats'] ?? const [];
    if (repeats is! List) throw const FormatException('백업에 잘못된 반복 규칙이 있습니다');
    return (
      tasks: _parseAll(data['tasks'] as List, Task.fromMap, (t) => t.id, '백업에 잘못된 태스크가 있습니다'),
      rules: _parseAll(repeats, RepeatRule.fromMap, (r) => r.id, '백업에 잘못된 반복 규칙이 있습니다'),
    );
  }

  static List<T> _parseAll<T>(List items, T Function(Map) parse, String Function(T) idOf, String error) {
    final byId = <String, T>{};
    for (final item in items) {
      if (item is! Map || item['id'] is! String || (item['id'] as String).isEmpty) {
        throw FormatException(error);
      }
      try {
        final value = parse(item);
        byId[idOf(value)] = value;
      } catch (_) {
        throw FormatException(error);
      }
    }
    return byId.values.toList();
  }
}
