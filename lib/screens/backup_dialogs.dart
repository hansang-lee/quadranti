import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/week.dart';
import '../providers/task_provider.dart';
import '../services/backup_files.dart';
import '../services/task_backup.dart';

/// The backup actions in one sheet: file save/open and clipboard copy/paste.
Future<void> showBackupSheet(BuildContext context) async {
  final action = await showModalBottomSheet<Future<void> Function(BuildContext)>(
    context: context,
    builder: (sheetContext) {
      ListTile item(Key key, IconData icon, String title, String subtitle, Future<void> Function(BuildContext) run) =>
          ListTile(
            key: key,
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            onTap: () => Navigator.pop(sheetContext, run),
          );
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            item(const Key('backupSaveFile'), Icons.download, '파일로 저장', '모든 주의 태스크를 JSON 파일로 저장', saveBackupFile),
            item(const Key('backupOpenFile'), Icons.upload_file, '파일에서 불러오기', '같은 태스크는 덮어쓰고, 다른 태스크는 그대로 둡니다', openBackupFile),
            item(const Key('backupCopy'), Icons.copy, '클립보드로 복사', '메모 앱 등에 붙여 넣어 보관', exportBackup),
            item(const Key('backupPaste'), Icons.paste, '붙여 넣어 가져오기', '복사해 둔 백업 내용을 붙여 넣기', importBackup),
          ],
        ),
      );
    },
  );
  if (action != null && context.mounted) await action(context);
}

/// `quadranti-backup-2026-10-07.json`
String backupFileName(DateTime now) => 'quadranti-backup-${formatDateKey(now)}.json';

/// Saves every task of the current user (all weeks) as a JSON file.
Future<void> saveBackupFile(BuildContext context) async {
  final provider = context.read<TaskProvider>();
  final tasks = provider.tasks;
  final messenger = ScaffoldMessenger.of(context);
  bool saved;
  try {
    saved = await backupFiles.save(backupFileName(DateTime.now()), TaskBackup.encode(tasks, rules: provider.rules));
  } catch (e) {
    _show(messenger, '파일을 저장하지 못했습니다: $e');
    return;
  }
  if (saved) _show(messenger, '태스크 ${tasks.length}개를 백업 파일로 저장했습니다');
}

/// Reads a backup file and merges it into the current user's tasks.
Future<void> openBackupFile(BuildContext context) async {
  final provider = context.read<TaskProvider>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final text = await backupFiles.open();
    if (text == null) return;
    final contents = TaskBackup.decode(text);
    final result = await provider.importTasks(contents.tasks, rules: contents.rules);
    _show(messenger, _importedMessage(result));
  } on FormatException catch (e) {
    _show(messenger, e.message);
  } catch (e) {
    _show(messenger, '파일을 읽지 못했습니다: $e');
  }
}

String _importedMessage(({int added, int replaced}) r) =>
    '가져오기 완료: 새 태스크 ${r.added}개, 덮어쓴 태스크 ${r.replaced}개';

void _show(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Copies every task of the current user (all weeks) to the clipboard.
Future<void> exportBackup(BuildContext context) async {
  final provider = context.read<TaskProvider>();
  final tasks = provider.tasks;
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: TaskBackup.encode(tasks, rules: provider.rules)));
  _show(messenger, '태스크 ${tasks.length}개를 클립보드에 복사했습니다. 메모 앱 등에 붙여 넣어 보관하세요.');
}

/// Asks for pasted backup text and merges it into the current user's tasks.
Future<void> importBackup(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await showDialog<({int added, int replaced})>(
    context: context,
    builder: (_) => const _ImportDialog(),
  );
  if (result == null) return;
  _show(messenger, _importedMessage(result));
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
      final contents = TaskBackup.decode(_text.text);
      final result = await context.read<TaskProvider>().importTasks(contents.tasks, rules: contents.rules);
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
