import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/task_backup.dart';

/// Copies every task of the current user (all weeks) to the clipboard.
Future<void> exportBackup(BuildContext context) async {
  final tasks = context.read<TaskProvider>().tasks;
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: TaskBackup.encode(tasks)));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('태스크 ${tasks.length}개를 클립보드에 복사했습니다. 메모 앱 등에 붙여 넣어 보관하세요.'),
    ));
}

/// Asks for pasted backup text and merges it into the current user's tasks.
Future<void> importBackup(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await showDialog<({int added, int replaced})>(
    context: context,
    builder: (_) => const _ImportDialog(),
  );
  if (result == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('가져오기 완료: 새 태스크 ${result.added}개, 덮어쓴 태스크 ${result.replaced}개'),
    ));
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _text = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final tasks = TaskBackup.decode(_text.text);
      final result = await context.read<TaskProvider>().importTasks(tasks);
      if (mounted) Navigator.pop(context, result);
    } on FormatException catch (e) {
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('백업 가져오기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('내보낸 백업 내용을 붙여 넣으세요. 같은 태스크는 백업 내용으로 덮어쓰고, 지금 있는 다른 태스크는 그대로 둡니다.'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('backupText'),
            controller: _text,
            maxLines: 6,
            minLines: 3,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: '{"app": "quadranti", ...}',
              errorText: _error,
              errorMaxLines: 2,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        TextButton(
          key: const Key('importBackup'),
          onPressed: _busy ? null : _import,
          child: const Text('가져오기'),
        ),
      ],
    );
  }
}
