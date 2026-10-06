import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/empty_week.dart';
import '../widgets/quadrant_painter.dart';
import 'task_editor_screen.dart';

/// The selected week's tasks on the quadrant graph. Tap a point to edit it;
/// a point shared by several tasks asks which one.
class GraphView extends StatelessWidget {
  const GraphView({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().weekTasks;
    if (tasks.isEmpty) return const EmptyWeek();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Largest square that fits, with room for the FAB.
        final side = math.max(
          0.0,
          math.min(constraints.maxWidth, constraints.maxHeight) - 32,
        );
        final size = Size(side, side);
        return Center(
          child: GestureDetector(
            key: const Key('graph'),
            onTapUp: (details) {
              final hit = QuadrantPainter.tasksAt(tasks, size, details.localPosition);
              if (hit.length == 1) {
                openTaskEditor(context, hit.single.id);
              } else if (hit.length > 1) {
                _pickTask(context, hit);
              }
            },
            child: CustomPaint(
              size: size,
              painter: QuadrantPainter(
                tasks: tasks,
                ink: Theme.of(context).colorScheme.onSurface,
                surface: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lets the user choose one of several tasks drawn on the same point.
void _pickTask(BuildContext context, List<Task> tasks) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final t in tasks)
            ListTile(
              leading: Icon(t.done ? Icons.check_box : Icons.check_box_outline_blank),
              title: Text(t.title),
              onTap: () {
                Navigator.pop(sheetContext);
                openTaskEditor(context, t.id);
              },
            ),
        ],
      ),
    ),
  );
}
