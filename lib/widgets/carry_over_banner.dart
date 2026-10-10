import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/week.dart';
import '../providers/task_provider.dart';

/// On the current week, offers to bring last week's unfinished tasks over.
/// Shows nothing on other weeks or when last week is all done.
class CarryOverBanner extends StatelessWidget {
  const CarryOverBanner({super.key, required this.onDismiss, this.now});

  final VoidCallback onDismiss;

  /// For tests; defaults to the task provider's clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final thisWeek = weekStartOf(now ?? tasks.now());
    if (tasks.selectedWeek != thisWeek) return const SizedBox.shrink();
    final lastWeek = addWeeks(thisWeek, -1);
    final count = tasks.carryOverCandidates(lastWeek, thisWeek).length;
    if (count == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Material(
      key: const Key('carryOverBanner'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Expanded(child: Text('지난 주에 끝내지 못한 태스크가 $count개 있어요')),
            TextButton(onPressed: onDismiss, child: const Text('닫기')),
            TextButton(
              key: const Key('carryOverAccept'),
              onPressed: () => tasks.carryOverUnfinished(from: lastWeek, to: thisWeek),
              child: const Text('이번 주로'),
            ),
          ],
        ),
      ),
    );
  }
}
