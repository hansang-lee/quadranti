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
        // Largest square that fits between a 16 dp margin and the + button,
        // which floats over the bottom of the body (16 dp margin + 56 dp
        // button + 16 dp gap). Centring the square used to put its lower
        // corner under the button on a 360 dp phone.
        const margin = 16.0;
        const fabReserve = 16.0 + 56.0 + 16.0;
        final side = math.max(
          0.0,
          math.min(constraints.maxWidth - 2 * margin, constraints.maxHeight - margin - fabReserve),
        );
        final size = Size(side, side);
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: margin),
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
