import '../core/week.dart';
import 'task_model.dart';

/// A task that comes back every week (D10). The rule keeps a template of the
/// task; [TaskProvider] creates one instance for the current week when the
/// week starts, with the id `<rule id>-<yyyy-MM-dd>` so it is made only once.
class RepeatRule {
  final String id;
  final String title;
  final String description;
  final double immediacy;
  final double effectiveness;
  final double waste;
  final double illusion;

  /// The latest week an instance was created for (or the week of the task
  /// the rule was made from). Weeks are never back-filled.
  final DateTime lastWeek;

  RepeatRule({
    required this.id,
    required this.title,
    this.description = '',
    this.immediacy = 5,
    this.effectiveness = 5,
    this.waste = 0,
    this.illusion = 0,
    required DateTime lastWeek,
  }) : lastWeek = weekStartOf(lastWeek);

  /// A rule whose template is [task]; [task.seriesId] must be set.
  factory RepeatRule.fromTask(Task task, {DateTime? lastWeek}) => RepeatRule(
        id: task.seriesId!,
        title: task.title,
        description: task.description,
        immediacy: task.immediacy,
        effectiveness: task.effectiveness,
        waste: task.waste,
        illusion: task.illusion,
        lastWeek: lastWeek ?? task.weekStart,
      );

  /// The same rule with its template taken from [task].
  RepeatRule withTemplate(Task task) => RepeatRule.fromTask(task, lastWeek: lastWeek);

  RepeatRule withLastWeek(DateTime week) => RepeatRule(
        id: id,
        title: title,
        description: description,
        immediacy: immediacy,
        effectiveness: effectiveness,
        waste: waste,
        illusion: illusion,
        lastWeek: week,
      );

  static String instanceId(String ruleId, DateTime week) => '$ruleId-${formatDateKey(week)}';

  /// The open instance for [week].
  Task instanceFor(DateTime week, {DateTime? createdAt}) => Task(
        id: instanceId(id, week),
        title: title,
        description: description,
        immediacy: immediacy,
        effectiveness: effectiveness,
        waste: waste,
        illusion: illusion,
        weekStart: week,
        seriesId: id,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'immediacy': immediacy,
        'effectiveness': effectiveness,
        'waste': waste,
        'illusion': illusion,
        'lastWeek': formatDateKey(lastWeek),
      };

  factory RepeatRule.fromMap(Map<dynamic, dynamic> map) => RepeatRule(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        immediacy: (map['immediacy'] as num?)?.toDouble() ?? 5,
        effectiveness: (map['effectiveness'] as num?)?.toDouble() ?? 5,
        waste: (map['waste'] as num?)?.toDouble() ?? 0,
        illusion: (map['illusion'] as num?)?.toDouble() ?? 0,
        lastWeek: parseDateKey(map['lastWeek'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is RepeatRule &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.immediacy == immediacy &&
      other.effectiveness == effectiveness &&
      other.waste == waste &&
      other.illusion == illusion &&
      other.lastWeek == lastWeek;

  @override
  int get hashCode => Object.hash(id, title, description, immediacy, effectiveness, waste, illusion, lastWeek);
}
