import 'package:flutter/material.dart';
import '../core/week.dart';
import '../models/repeat_rule.dart';
import '../models/task_model.dart';
import '../services/task_repository.dart';

typedef RepositoryFactory = TaskRepository Function(String userId);

/// The signed-in user's tasks and the week being viewed.
///
/// Changes are applied in memory first and then written to the repository.
class TaskProvider with ChangeNotifier {
  /// [now] fixes the clock (tests); [clock] lets it move.
  TaskProvider({RepositoryFactory? repositoryFor, DateTime? now, DateTime Function()? clock})
      : _repositoryFor = repositoryFor ?? HiveTaskRepository.new,
        _clock = clock ?? (now != null ? () => now : DateTime.now),
        _selectedWeek = weekStartOf((clock ?? (() => now ?? DateTime.now()))());

  final RepositoryFactory _repositoryFor;
  final DateTime Function() _clock;
  TaskRepository? _repository;
  String? _userId;
  int _loadGeneration = 0;

  // Replaced (never mutated) on every change, so listeners such as
  // QuadrantPainter.shouldRepaint can detect a change by identity.
  List<Task> _tasks = const [];
  Map<String, RepeatRule> _rules = const {};
  bool _isLoading = false;
  DateTime _selectedWeek;

  /// Every task of the current user, across all weeks.
  List<Task> get tasks => _tasks;

  /// The current user's repeat rules (D10).
  List<RepeatRule> get rules => List.unmodifiable(_rules.values);

  /// Whether [task] belongs to a series that still repeats.
  bool isRepeating(Task task) => task.seriesId != null && _rules.containsKey(task.seriesId);
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  DateTime get selectedWeek => _selectedWeek;

  /// Tasks scheduled in [selectedWeek]. Cached, so the same list instance
  /// is returned until the tasks or the week change.
  List<Task> get weekTasks {
    if (!identical(_weekTasksSource, _tasks) || _weekTasksWeek != _selectedWeek) {
      _weekTasksSource = _tasks;
      _weekTasksWeek = _selectedWeek;
      _weekTasks = List.unmodifiable(_tasks.where((t) => t.weekStart == _selectedWeek));
    }
    return _weekTasks;
  }

  List<Task>? _weekTasksSource;
  DateTime? _weekTasksWeek;
  List<Task> _weekTasks = const [];

  /// Switches to [userId]'s tasks (or none when null) and loads them.
  Future<void> setUser(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    _repository = userId == null ? null : _repositoryFor(userId);
    _tasks = const [];
    _rules = const {};
    final generation = ++_loadGeneration;
    if (_repository == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    List<Task> loaded = const [];
    List<RepeatRule> loadedRules = const [];
    try {
      loaded = await _repository!.loadAll();
      loadedRules = await _repository!.loadRules();
    } catch (e) {
      // Leave the list empty rather than stuck loading. Writes still go to
      // the user's box, so nothing stored is overwritten wholesale.
      debugPrint('Loading tasks for $userId failed: $e');
    }
    // A newer setUser call has taken over; drop this result.
    if (generation != _loadGeneration) return;
    _tasks = List.unmodifiable(loaded);
    _rules = {for (final r in loadedRules) r.id: r};
    _isLoading = false;
    notifyListeners();
    await createDueRepeats();
  }

  void selectWeek(DateTime date) {
    _selectedWeek = weekStartOf(date);
    notifyListeners();
    // Cheap when nothing is due; catches an app left open into a new week.
    createDueRepeats();
  }

  /// For every rule not yet run for the current calendar week, adds that
  /// week's instance (unless one is already there) and records the week.
  /// Missed weeks in between are not back-filled.
  Future<void> createDueRepeats() async {
    final repository = _repository;
    if (repository == null) return;
    final week = weekStartOf(_clock());
    final due = _rules.values.where((r) => r.lastWeek.isBefore(week)).toList();
    if (due.isEmpty) return;

    final created = <Task>[];
    for (final rule in due) {
      final id = RepeatRule.instanceId(rule.id, week);
      final exists = _tasks.any((t) => t.id == id || (t.seriesId == rule.id && t.weekStart == week));
      if (!exists) created.add(rule.instanceFor(week, createdAt: _clock()));
    }
    final updatedRules = [for (final r in due) r.withLastWeek(week)];
    _tasks = List.unmodifiable([..._tasks, ...created]);
    _rules = {..._rules, for (final r in updatedRules) r.id: r};
    notifyListeners();
    for (final t in created) {
      await repository.put(t);
    }
    for (final r in updatedRules) {
      await repository.putRule(r);
    }
  }

  /// Starts or stops repeating [task] weekly. Starting gives it a series
  /// (its own id) and a rule whose template is the task; the first new
  /// instance comes with the next calendar week (never the current one, and
  /// never a week the series already reached). Stopping deletes the rule,
  /// and existing instances stay.
  Future<void> setRepeat(Task task, bool repeat) async {
    final repository = _repository;
    if (byId(task.id) == null || repository == null) return;
    if (!repeat) {
      final id = task.seriesId;
      if (id == null || !_rules.containsKey(id)) return;
      _rules = {..._rules}..remove(id);
      notifyListeners();
      await repository.deleteRule(id);
      return;
    }
    if (isRepeating(task)) return;
    final inSeries = task.seriesId == null ? task.copyWith(seriesId: task.id) : task;
    var start = task.weekStart;
    final thisWeek = weekStartOf(_clock());
    if (thisWeek.isAfter(start)) start = thisWeek;
    for (final t in _tasks) {
      if (t.seriesId == inSeries.seriesId && t.weekStart.isAfter(start)) start = t.weekStart;
    }
    final rule = RepeatRule.fromTask(inSeries, lastWeek: start);
    _tasks = List.unmodifiable(_tasks.map((t) => t.id == task.id ? inSeries : t));
    _rules = {..._rules, rule.id: rule};
    notifyListeners();
    await repository.put(inSeries);
    await repository.putRule(rule);
  }

  void shiftWeek(int weeks) => selectWeek(addWeeks(_selectedWeek, weeks));

  Task? byId(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> addTask(Task task) async {
    _tasks = List.unmodifiable([..._tasks, task]);
    notifyListeners();
    await _repository?.put(task);
  }

  /// Replaces the task with the same id. Does nothing when the current user
  /// has no such task (e.g. an editor left open across a user switch).
  /// Editing a repeating task also updates its rule's template, so later
  /// weeks get the new title and scores.
  Future<void> updateTask(Task task) async {
    if (byId(task.id) == null) return;
    final repository = _repository;
    _tasks = List.unmodifiable(_tasks.map((t) => t.id == task.id ? task : t));
    // Only the series' newest instance sets the template; ticking or
    // editing an older week must not roll later weeks back.
    final current = isRepeating(task) ? _rules[task.seriesId]! : null;
    final rule = current != null && !task.weekStart.isBefore(current.lastWeek) ? current.withTemplate(task) : null;
    if (rule != null) _rules = {..._rules, rule.id: rule};
    notifyListeners();
    await repository?.put(task);
    if (rule != null) await repository?.putRule(rule);
  }

  Future<void> removeTask(String id) async {
    _tasks = List.unmodifiable(_tasks.where((task) => task.id != id));
    notifyListeners();
    await _repository?.delete(id);
  }

  Future<void> toggleDone(String id) async {
    final task = byId(id);
    if (task != null) await updateTask(task.copyWith(done: !task.done));
  }

  /// Unfinished tasks scheduled in the week starting [weekStart].
  List<Task> unfinishedIn(DateTime weekStart) =>
      _tasks.where((t) => !t.done && t.weekStart == weekStart).toList();

  /// Unfinished tasks of week [from] that can move to week [to]: a repeating
  /// task stays behind when its series already has an instance in [to].
  List<Task> carryOverCandidates(DateTime from, DateTime to) {
    final seriesInTarget = {
      for (final t in _tasks)
        if (t.weekStart == to && t.seriesId != null) t.seriesId,
    };
    return unfinishedIn(from).where((t) => t.seriesId == null || !seriesInTarget.contains(t.seriesId)).toList();
  }

  /// Moves the [carryOverCandidates] of week [from] (default: [selectedWeek])
  /// into week [to] (default: the week after [from]). Returns how many
  /// were moved.
  Future<int> carryOverUnfinished({DateTime? from, DateTime? to}) async {
    final source = from ?? _selectedWeek;
    final target = to ?? addWeeks(source, 1);
    final moved = {for (final t in carryOverCandidates(source, target)) t.id: t.copyWith(weekStart: target)};
    _tasks = List.unmodifiable(_tasks.map((t) => moved[t.id] ?? t));
    notifyListeners();
    await _putAll(moved.values);
    return moved.length;
  }

  /// Writes [tasks] to the repository of the user current at the time of
  /// the call. Batch operations go through here so that a user switch
  /// mid-way cannot send the remaining writes to the next user's box.
  Future<void> _putAll(Iterable<Task> tasks) async {
    final repository = _repository;
    for (final t in tasks.toList()) {
      await repository?.put(t);
    }
  }

  /// Adds [imported] tasks and [rules], replacing any with the same id.
  /// Nothing is deleted. A replaced rule keeps the later of the two
  /// lastWeek values, so no week is created twice. Returns how many tasks
  /// were new and how many replaced.
  Future<({int added, int replaced})> importTasks(List<Task> imported, {List<RepeatRule> rules = const []}) async {
    final repository = _repository;
    final byId = {for (final t in _tasks) t.id: t};
    var added = 0;
    var replaced = 0;
    for (final t in imported) {
      byId.containsKey(t.id) ? replaced++ : added++;
      byId[t.id] = t;
    }
    final mergedRules = [
      for (final r in rules)
        switch (_rules[r.id]) {
          final old? when old.lastWeek.isAfter(r.lastWeek) => r.withLastWeek(old.lastWeek),
          _ => r,
        },
    ];
    _tasks = List.unmodifiable(byId.values);
    _rules = {..._rules, for (final r in mergedRules) r.id: r};
    notifyListeners();
    await _putAll(imported);
    for (final r in mergedRules) {
      await repository?.putRule(r);
    }
    await createDueRepeats();
    return (added: added, replaced: replaced);
  }

  /// Adds four example tasks, one per quadrant, to [selectedWeek].
  Future<void> loadSampleData() async {
    final week = _selectedWeek;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final samples = [
      Task(id: '$stamp-1', title: '핵심 프로젝트 마감', immediacy: 8, effectiveness: 9, weekStart: week),
      Task(id: '$stamp-2', title: '형식적인 회의', immediacy: 9, effectiveness: 2, waste: 8, illusion: 8, weekStart: week),
      Task(id: '$stamp-3', title: '장기 전략 정리', immediacy: 2, effectiveness: 9, illusion: 4, weekStart: week),
      Task(id: '$stamp-4', title: '무한 스크롤', immediacy: 5, effectiveness: 0, waste: 9, illusion: 8, weekStart: week),
    ];
    _tasks = List.unmodifiable([..._tasks, ...samples]);
    notifyListeners();
    await _putAll(samples);
  }
}
