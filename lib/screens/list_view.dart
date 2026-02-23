import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return ListView.builder(
          itemCount: taskProvider.tasks.length,
          itemBuilder: (context, index) {
            final task = taskProvider.tasks[index];
            return ListTile(
              title: Text(task.title),
              subtitle: Text("Q${task.quadrant} | Eff: ${task.effectiveness} Imm: ${task.immediacy}"),
              leading: CircleAvatar(
                child: Text("${task.quadrant}"),
              ),
            );
          },
        );
      },
    );
  }
}
