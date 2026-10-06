import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/week_format.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/week_summary.dart';
import 'backup_dialogs.dart';
import 'graph_view.dart';
import 'list_view.dart';
import 'task_editor_screen.dart';

enum _MenuAction { carryOver, samples, exportBackup, importBackup, signOut }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    GraphView(),
    TaskListView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _onMenu(_MenuAction action) async {
    final tasks = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _MenuAction.carryOver:
        final moved = await tasks.carryOverUnfinished();
        messenger.showSnackBar(SnackBar(
          content: Text(moved == 0 ? '옮길 미완료 태스크가 없습니다' : '미완료 $moved개를 다음 주로 옮겼습니다'),
        ));
      case _MenuAction.samples:
        await tasks.loadSampleData();
      case _MenuAction.exportBackup:
        await exportBackup(context);
      case _MenuAction.importBackup:
        await importBackup(context);
      case _MenuAction.signOut:
        await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final week = tasks.selectedWeek;
    final relative = relativeWeekName(week);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('prevWeek'),
          icon: const Icon(Icons.chevron_left),
          tooltip: '이전 주',
          onPressed: () => tasks.shiftWeek(-1),
        ),
        titleSpacing: 0,
        title: InkWell(
          // Tapping the title jumps back to this week.
          onTap: () => tasks.selectWeek(DateTime.now()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formatWeekRange(week), key: const Key('weekTitle')),
              Text(
                relative ?? auth.currentUser?.displayName ?? '',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            key: const Key('nextWeek'),
            icon: const Icon(Icons.chevron_right),
            tooltip: '다음 주',
            onPressed: () => tasks.shiftWeek(1),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: _onMenu,
            itemBuilder: (context) => [
              const PopupMenuItem(value: _MenuAction.carryOver, child: Text('미완료를 다음 주로')),
              const PopupMenuItem(value: _MenuAction.samples, child: Text('예시 태스크 추가')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: _MenuAction.exportBackup, child: Text('백업 내보내기 (클립보드)')),
              const PopupMenuItem(value: _MenuAction.importBackup, child: Text('백업 가져오기')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _MenuAction.signOut,
                child: Text('로그아웃 (${auth.currentUser?.displayName ?? ''})'),
              ),
            ],
          ),
        ],
      ),
      body: tasks.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (tasks.weekTasks.isNotEmpty) WeekSummary(tasks: tasks.weekTasks),
                Expanded(child: _widgetOptions.elementAt(_selectedIndex)),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: '그래프',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '목록',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addTask'),
        tooltip: '태스크 추가',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TaskEditorScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
