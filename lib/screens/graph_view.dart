import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/empty_week.dart';
import '../widgets/quadrant_painter.dart';
import 'task_editor_screen.dart';

/// The selected week's tasks on the quadrant graph. Tap a point to edit it.
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
              final task = QuadrantPainter.taskAt(tasks, size, details.localPosition);
              if (task != null) openTaskEditor(context, task.id);
            },
            child: CustomPaint(
              size: size,
              painter: QuadrantPainter(tasks: tasks),
            ),
          ),
        );
      },
    );
  }
}
