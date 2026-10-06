import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  // Replaced (never mutated) on every change, so listeners such as
  // QuadrantPainter.shouldRepaint can detect a change by identity.
  List<Task> _tasks = const [];

  List<Task> get tasks => _tasks;

  void addTask(Task task) {
    _tasks = List.unmodifiable([..._tasks, task]);
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks = List.unmodifiable(_tasks.where((task) => task.id != id));
    notifyListeners();
  }
  
  /// Seeds four example tasks, one per quadrant. Does nothing once any task
  /// exists, so calling it again (e.g. after a re-login) cannot duplicate them.
  void loadSampleData() {
    if (_tasks.isNotEmpty) return;
    _tasks = List.unmodifiable([
      Task(id: '1', title: 'Critical Project', immediacy: 8, effectiveness: 9),
      Task(id: '2', title: 'Useless Meeting', immediacy: 9, effectiveness: 2, waste: 8, illusion: 8),
      Task(id: '3', title: 'Long-term Strategy', immediacy: 2, effectiveness: 9, illusion: 4),
      Task(id: '4', title: 'Doom Scrolling', immediacy: 5, effectiveness: 0, waste: 9, illusion: 8),
    ]);
    notifyListeners();
  }
}
