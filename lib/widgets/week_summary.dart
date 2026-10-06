import 'package:flutter/material.dart';
import '../core/quadrant_style.dart';
import '../models/task_model.dart';

/// One line above the graph/list: tasks per quadrant and how many are done.
class WeekSummary extends StatelessWidget {
  const WeekSummary({super.key, required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = tasks.where((t) => t.done).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Wraps onto a second line on narrow screens instead of overflowing.
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final q in Quadrant.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: q.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${q.label} ${tasks.where((t) => t.quadrant == q).length}',
                        key: Key('summary_${q.name}'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Text(
            '완료 $done/${tasks.length}',
            key: const Key('summary_done'),
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
