import '../core/constants.dart';
import '../core/week.dart';

/// Where a task lands on the graph. See docs/concept.md.
enum Quadrant {
  focus(1, '집중'), // top-right: real value, really urgent
  caution(2, '주의'), // top-left: urgent but little value (busy trap)
  eliminate(3, '제거'), // bottom-left: neither
  plan(4, '계획'); // bottom-right: valuable, not urgent

  const Quadrant(this.number, this.label);
  final int number;
  final String label;
}

/// A task rated on four 0..[AppConstants.scoreMax] scores. Immutable; use
/// [copyWith] to change it.
class Task {
  final String id;
  final String title;
  final String description;

  // The four properties. Each is clamped to 0..scoreMax.
  final double immediacy;
  final double effectiveness;
  final double waste;
  final double illusion;

  /// Monday of the week this task is scheduled in (see core/week.dart).
  final DateTime weekStart;
  final bool done;
  final DateTime createdAt;

  /// Id of the [RepeatRule] this task belongs to, if it was ever made to
  /// repeat. Whether it still repeats depends on that rule existing.
  final String? seriesId;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    double immediacy = 5.0,
    double effectiveness = 5.0,
    double waste = 0.0,
    double illusion = 0.0,
    DateTime? weekStart,
    this.done = false,
    DateTime? createdAt,
    this.seriesId,
  })  : immediacy = _clampScore(immediacy),
        effectiveness = _clampScore(effectiveness),
        waste = _clampScore(waste),
        illusion = _clampScore(illusion),
        weekStart = weekStartOf(weekStart ?? DateTime.now()),
        createdAt = createdAt ?? DateTime.now();

  static double _clampScore(double v) =>
      v.isNaN ? 0.0 : v.clamp(0.0, AppConstants.scoreMax).toDouble();

  // Coordinates relative to the centre (0,0), each in -scoreMax..scoreMax.
  // X (value)           = Effectiveness - Waste
  // Y (real urgency)    = Immediacy - Illusion
  double get x => effectiveness - waste;
  double get y => immediacy - illusion;

  // 0..1 across the graph; normalizedY 1.0 is the top edge.
  double get normalizedX => (x + AppConstants.scoreMax) / (AppConstants.scoreMax * 2);
  double get normalizedY => (y + AppConstants.scoreMax) / (AppConstants.scoreMax * 2);

  // Points on an axis count toward the right / upper side.
  Quadrant get quadrant {
    if (x >= 0 && y >= 0) return Quadrant.focus;
    if (x < 0 && y >= 0) return Quadrant.caution;
    if (x < 0 && y < 0) return Quadrant.eliminate;
    return Quadrant.plan;
  }

  Task copyWith({
    String? title,
    String? description,
    double? immediacy,
    double? effectiveness,
    double? waste,
    double? illusion,
    DateTime? weekStart,
    bool? done,
    String? seriesId,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        immediacy: immediacy ?? this.immediacy,
        effectiveness: effectiveness ?? this.effectiveness,
        waste: waste ?? this.waste,
        illusion: illusion ?? this.illusion,
        weekStart: weekStart ?? this.weekStart,
        done: done ?? this.done,
        createdAt: createdAt,
        seriesId: seriesId ?? this.seriesId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'immediacy': immediacy,
        'effectiveness': effectiveness,
        'waste': waste,
        'illusion': illusion,
        'weekStart': formatDateKey(weekStart),
        'done': done,
        'createdAt': createdAt.toIso8601String(),
        if (seriesId != null) 'seriesId': seriesId,
      };

  /// Tolerates missing keys so older stored records still load.
  factory Task.fromMap(Map<dynamic, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        immediacy: (map['immediacy'] as num?)?.toDouble() ?? 5.0,
        effectiveness: (map['effectiveness'] as num?)?.toDouble() ?? 5.0,
        waste: (map['waste'] as num?)?.toDouble() ?? 0.0,
        illusion: (map['illusion'] as num?)?.toDouble() ?? 0.0,
        weekStart: map['weekStart'] is String ? parseDateKey(map['weekStart'] as String) : null,
        done: map['done'] as bool? ?? false,
        createdAt: map['createdAt'] is String ? DateTime.tryParse(map['createdAt'] as String) : null,
        seriesId: map['seriesId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.immediacy == immediacy &&
      other.effectiveness == effectiveness &&
      other.waste == waste &&
      other.illusion == illusion &&
      other.weekStart == weekStart &&
      other.done == done &&
      other.createdAt == createdAt &&
      other.seriesId == seriesId;

  @override
  int get hashCode => Object.hash(id, title, description, immediacy, effectiveness, waste,
      illusion, weekStart, done, createdAt, seriesId);
}
