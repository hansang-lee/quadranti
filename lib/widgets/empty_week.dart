import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

/// Shown in place of the graph or list when the week has no tasks.
class EmptyWeek extends StatelessWidget {
  const EmptyWeek({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('이 주에 등록된 태스크가 없습니다', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '+ 버튼으로 태스크를 추가하고, 네 가지 속성을 매겨 보세요.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('loadSamples'),
              onPressed: () => context.read<TaskProvider>().loadSampleData(),
              child: const Text('예시 태스크 불러오기'),
            ),
          ],
        ),
      ),
    );
  }
}
