import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/quadrant_style.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

/// Opens the editor for an existing task.
void openTaskEditor(BuildContext context, String taskId) {
  final task = context.read<TaskProvider>().byId(taskId);
  if (task == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task)),
  );
}

/// Creates a task in the selected week, or edits [task] when given.
class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late double _immediacy;
  late double _effectiveness;
  late double _waste;
  late double _illusion;

  bool get _isNew => widget.task == null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _immediacy = t?.immediacy ?? 5;
    _effectiveness = t?.effectiveness ?? 5;
    _waste = t?.waste ?? 0;
    _illusion = t?.illusion ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Task _draft(TaskProvider tasks) {
    final base = widget.task ??
        Task(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: '',
          weekStart: tasks.selectedWeek,
        );
    return base.copyWith(
      title: _title.text.trim(),
      description: _description.text.trim(),
      immediacy: _immediacy,
      effectiveness: _effectiveness,
      waste: _waste,
      illusion: _illusion,
    );
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }
    final tasks = context.read<TaskProvider>();
    final task = _draft(tasks);
    final navigator = Navigator.of(context);
    if (_isNew) {
      await tasks.addTask(task);
    } else {
      await tasks.updateTask(task);
    }
    navigator.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태스크 삭제'),
        content: Text('"${widget.task!.title}"을(를) 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    await context.read<TaskProvider>().removeTask(widget.task!.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _draft(context.read<TaskProvider>());
    final q = preview.quadrant;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '새 태스크' : '태스크 편집'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '삭제',
              onPressed: _delete,
            ),
          TextButton(
            key: const Key('save'),
            onPressed: _save,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(_isNew ? '추가' : '저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('title'),
            controller: _title,
            autofocus: _isNew,
            decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: '메모 (선택)', border: OutlineInputBorder()),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          Card(
            key: const Key('quadrantPreview'),
            color: q.color.withValues(alpha: 0.12),
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: q.color,
                foregroundColor: Colors.white,
                child: Text('${q.number}'),
              ),
              title: Text('${q.label} (Q${q.number})'),
              subtitle: Text('${q.hint}\n가치 ${_signed(preview.x)} · 실제 긴급도 ${_signed(preview.y)}'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 8),
          _ScoreSlider(
            label: '효과',
            help: '이 일이 목표에 실제로 기여하는 정도',
            value: _effectiveness,
            onChanged: (v) => setState(() => _effectiveness = v),
          ),
          _ScoreSlider(
            label: '낭비',
            help: '들이는 시간·에너지 대비 남는 게 없는 정도',
            value: _waste,
            onChanged: (v) => setState(() => _waste = v),
          ),
          _ScoreSlider(
            label: '즉시성',
            help: '지금 처리하지 않으면 실제로 문제가 되는 정도',
            value: _immediacy,
            onChanged: (v) => setState(() => _immediacy = v),
          ),
          _ScoreSlider(
            label: '착각',
            help: '급해 보이지만 사실은 급하지 않은 정도',
            value: _illusion,
            onChanged: (v) => setState(() => _illusion = v),
          ),
        ],
      ),
    );
  }

  static String _signed(double v) {
    final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return v > 0 ? '+$s' : s;
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String help;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(value.toStringAsFixed(0), style: theme.textTheme.titleSmall),
            ],
          ),
          Text(help, style: theme.textTheme.bodySmall),
          Slider(
            key: Key('slider_$label'),
            value: value,
            min: 0,
            max: AppConstants.scoreMax,
            divisions: AppConstants.scoreMax.toInt(),
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
