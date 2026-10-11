import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/quadrant_style.dart';
import '../core/week.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

/// "2026년 10월".
String formatMonth(DateTime month) => '${month.year}년 ${month.month}월';

/// The month a week is shown under when it is first opened: the month of
/// its Thursday, so a week split across two months goes where most of its
/// days are.
DateTime monthOfWeek(DateTime weekStart) {
  final thursday = DateTime(weekStart.year, weekStart.month, weekStart.day + 3);
  return DateTime(thursday.year, thursday.month);
}

/// The Mondays of every week that has at least one day in [month].
List<DateTime> weeksOfMonth(DateTime month) {
  final last = DateTime(month.year, month.month + 1, 0);
  final weeks = <DateTime>[];
  for (var w = weekStartOf(DateTime(month.year, month.month)); !w.isAfter(last); w = addWeeks(w, 1)) {
    weeks.add(w);
  }
  return weeks;
}

/// A month as rows of weeks (D11). Tasks belong to a week, not a day (D2),
/// so each week row lists its tasks under its seven days; tapping a row
/// opens that week through [onOpenWeek].
class MonthView extends StatefulWidget {
  const MonthView({super.key, required this.onOpenWeek});

  final ValueChanged<DateTime> onOpenWeek;

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  late DateTime _month = monthOfWeek(context.read<TaskProvider>().selectedWeek);

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final today = DateTime(tasks.now().year, tasks.now().month, tasks.now().day);
    final byWeek = <DateTime, List<Task>>{};
    for (final t in tasks.tasks) {
      byWeek.putIfAbsent(t.weekStart, () => []).add(t);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                key: const Key('prevMonth'),
                icon: const Icon(Icons.chevron_left),
                tooltip: '이전 달',
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: InkWell(
                  // Tapping the month jumps back to the current one.
                  onTap: () => setState(() => _month = DateTime(today.year, today.month)),
                  child: Text(
                    formatMonth(_month),
                    key: const Key('monthTitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                key: const Key('nextMonth'),
                icon: const Icon(Icons.chevron_right),
                tooltip: '다음 달',
                onPressed: () => _shift(1),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final (i, d) in ['월', '화', '수', '목', '금', '토', '일'].indexed)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == 6 ? Colors.red.shade400 : i == 5 ? Colors.blue.shade400 : theme.colorScheme.outline,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
            children: [
              for (final week in weeksOfMonth(_month))
                _WeekRow(
                  week: week,
                  month: _month,
                  today: today,
                  tasks: byWeek[week] ?? const [],
                  selected: week == tasks.selectedWeek,
                  onTap: () => widget.onOpenWeek(week),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.month,
    required this.today,
    required this.tasks,
    required this.selected,
    required this.onTap,
  });

  final DateTime week;
  final DateTime month;
  final DateTime today;
  final List<Task> tasks;
  final bool selected;
  final VoidCallback onTap;

  static const _shownTitles = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = tasks.where((t) => t.done).length;
    final open = tasks.where((t) => !t.done).toList()..sort((a, b) => a.quadrant.index.compareTo(b.quadrant.index));

    return Card(
      key: Key('monthWeek_${formatDateKey(week)}'),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.5) : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected ? BorderSide(color: scheme.primary, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 7; i++) Expanded(child: _day(context, DateTime(week.year, week.month, week.day + i))),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: tasks.isEmpty
                    ? Text('태스크 없음', style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final q in Quadrant.values)
                                if (tasks.any((t) => t.quadrant == q))
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: q.color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 3),
                                      Text('${q.label} ${tasks.where((t) => t.quadrant == q).length}',
                                          style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                              Text('완료 $done/${tasks.length}',
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          for (final t in open.take(_shownTitles))
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 6),
                                    color: t.quadrant.color,
                                  ),
                                  Expanded(
                                    child: Text(t.title,
                                        maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                                  ),
                                ],
                              ),
                            ),
                          if (open.length > _shownTitles)
                            Text('외 ${open.length - _shownTitles}개',
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _day(BuildContext context, DateTime day) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inMonth = day.month == month.month;
    final isToday = day == today;
    final weekday = day.weekday;
    var color = weekday == DateTime.sunday
        ? Colors.red.shade400
        : weekday == DateTime.saturday
            ? Colors.blue.shade400
            : scheme.onSurface;
    if (!inMonth) color = color.withValues(alpha: 0.35);
    return Center(
      child: Container(
        key: isToday ? const Key('monthToday') : null,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: isToday ? BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(10)) : null,
        child: Text(
          '${day.day}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isToday ? scheme.onPrimary : color,
            fontWeight: isToday ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}
