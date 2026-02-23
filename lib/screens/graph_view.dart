import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/quadrant_painter.dart';

class GraphView extends StatelessWidget {
  const GraphView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: QuadrantPainter(tasks: taskProvider.tasks),
              ),
            ),
          ),
        );
      },
    );
  }
}
