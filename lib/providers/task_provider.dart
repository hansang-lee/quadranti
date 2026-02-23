import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }
  
  // Method to add dummy data for testing
  void loadDummyData() {
    _tasks.addAll([
      Task(id: '1', title: 'Critical Project', immediacy: 8, effectiveness: 9),
      Task(id: '2', title: 'Useless Meeting', immediacy: 9, effectiveness: 2, waste: 8, illusion: 8),
      Task(id: '3', title: 'Long-term Strategy', immediacy: 2, effectiveness: 9),
      Task(id: '4', title: 'Doom Scrolling', immediacy: 5, effectiveness: 0, waste: 9),
    ]);
    notifyListeners();
  }
}
