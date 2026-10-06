import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/quadrant_style.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/empty_week.dart';
import 'task_editor_screen.dart';

/// The selected week's tasks, grouped by quadrant (Q1 first), open tasks
/// before finished ones.
class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.weekTasks;
    if (tasks.isEmpty) return const EmptyWeek();

    final children = <Widget>[];
    for (final q in Quadrant.values) {
      final group = tasks.where((t) => t.quadrant == q).toList()
        ..sort((a, b) {
          if (a.done != b.done) return a.done ? 1 : -1;
          return a.createdAt.compareTo(b.createdAt);
        });
      if (group.isEmpty) continue;
      children.add(_QuadrantHeader(quadrant: q, count: group.length));
      children.addAll(group.map((t) => _TaskTile(task: t)));
    }
    return ListView(padding: const EdgeInsets.only(bottom: 88), children: children);
  }
}

class _QuadrantHeader extends StatelessWidget {
  const _QuadrantHeader({required this.quadrant, required this.count});

  final Quadrant quadrant;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: quadrant.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${quadrant.label} · $count',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              quadrant.hint,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  Future<void> _delete(BuildContext context) async {
    final tasks = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await tasks.removeTask(task.id);
    messenger.showSnackBar(SnackBar(
      content: Text('"${task.title}" 삭제됨'),
      action: SnackBarAction(label: '되돌리기', onPressed: () => tasks.addTask(task)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => _delete(context),
      child: ListTile(
        leading: Checkbox(
          value: task.done,
          onChanged: (_) => context.read<TaskProvider>().toggleDone(task.id),
        ),
        title: Text(
          task.title,
          style: task.done
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                )
              : null,
        ),
        subtitle: task.description.isEmpty
            ? null
            : Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: CircleAvatar(
          radius: 12,
          backgroundColor: task.quadrant.color,
          foregroundColor: Colors.white,
          child: Text('${task.quadrant.number}', style: const TextStyle(fontSize: 12)),
        ),
        onTap: () => openTaskEditor(context, task.id),
      ),
    );
  }
}
