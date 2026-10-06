import 'package:flutter/material.dart';
import '../core/week.dart';
import '../models/task_model.dart';
import '../services/task_repository.dart';

typedef RepositoryFactory = TaskRepository Function(String userId);

/// The signed-in user's tasks and the week being viewed.
///
/// Changes are applied in memory first and then written to the repository.
class TaskProvider with ChangeNotifier {
  TaskProvider({RepositoryFactory? repositoryFor, DateTime? now})
      : _repositoryFor = repositoryFor ?? HiveTaskRepository.new,
        _selectedWeek = weekStartOf(now ?? DateTime.now());

  final RepositoryFactory _repositoryFor;
  TaskRepository? _repository;
  String? _userId;
  int _loadGeneration = 0;

  // Replaced (never mutated) on every change, so listeners such as
  // QuadrantPainter.shouldRepaint can detect a change by identity.
  List<Task> _tasks = const [];
  bool _isLoading = false;
  DateTime _selectedWeek;

  /// Every task of the current user, across all weeks.
  List<Task> get tasks => _tasks;
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
    final generation = ++_loadGeneration;
    if (_repository == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    List<Task> loaded = const [];
    try {
      loaded = await _repository!.loadAll();
    } catch (e) {
      // Leave the list empty rather than stuck loading. Writes still go to
      // the user's box, so nothing stored is overwritten wholesale.
      debugPrint('Loading tasks for $userId failed: $e');
    }
    // A newer setUser call has taken over; drop this result.
    if (generation != _loadGeneration) return;
    _tasks = List.unmodifiable(loaded);
    _isLoading = false;
    notifyListeners();
  }

  void selectWeek(DateTime date) {
    _selectedWeek = weekStartOf(date);
    notifyListeners();
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
  Future<void> updateTask(Task task) async {
    if (byId(task.id) == null) return;
    _tasks = List.unmodifiable(_tasks.map((t) => t.id == task.id ? task : t));
    notifyListeners();
    await _repository?.put(task);
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

  /// Moves every unfinished task of the week [from] (default: [selectedWeek])
  /// into the week [to] (default: the week after [from]). Returns how many
  /// were moved.
  Future<int> carryOverUnfinished({DateTime? from, DateTime? to}) async {
    final source = from ?? _selectedWeek;
    final target = to ?? addWeeks(source, 1);
    final moved = {for (final t in unfinishedIn(source)) t.id: t.copyWith(weekStart: target)};
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

  /// Adds [imported] tasks, replacing any existing task with the same id.
  /// Nothing is deleted. Returns how many were new and how many replaced.
  Future<({int added, int replaced})> importTasks(List<Task> imported) async {
    final byId = {for (final t in _tasks) t.id: t};
    var added = 0;
    var replaced = 0;
    for (final t in imported) {
      byId.containsKey(t.id) ? replaced++ : added++;
      byId[t.id] = t;
    }
    _tasks = List.unmodifiable(byId.values);
    notifyListeners();
    await _putAll(imported);
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
