import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quadranti/core/week.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/models/user_model.dart';
import 'package:quadranti/providers/auth_provider.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/screens/guide_screen.dart';
import 'package:quadranti/screens/home_screen.dart';
import 'package:quadranti/services/prefs.dart';
import 'package:quadranti/services/task_repository.dart';

class _FakeAuth extends AuthProvider {
  @override
  User? get currentUser => User(id: 'u', email: 'u@x.com', displayName: 'U');
}

void main() {
  late TaskProvider tasks;

  Future<void> pumpHome(WidgetTester tester) async {
    // Tall phone-width screen so the whole editor is built without scrolling.
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tasks = TaskProvider(repositoryFor: (_) => MemoryTaskRepository());
    await tasks.setUser('u');
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(value: tasks),
        ChangeNotifierProvider<AuthProvider>.value(value: _FakeAuth()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('empty week offers samples, which then show on the graph', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);
    expect(find.text('이 주에 등록된 태스크가 없습니다'), findsOneWidget);

    await tester.tap(find.byKey(const Key('loadSamples')));
    await tester.pumpAndSettle();
    expect(tasks.weekTasks, hasLength(4));
    expect(find.byKey(const Key('graph')), findsOneWidget);
    // Each dot is visible to screen readers.
    expect(find.semantics.byLabel(RegExp(r'^무한 스크롤\. 제거 사분면')), findsOne);
    semantics.dispose();
  });

  testWidgets('add a task through the editor and see it in the list', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('목록'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addTask')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title')), '분기 보고서');
    // Drag "착각" to the right end: urgency 5 - 10 < 0, value 5 >= 0 -> 계획.
    await tester.drag(find.byKey(const Key('slider_착각')), const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(const Key('quadrantPreview')), matching: find.text('계획 (Q4)')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('save')));
    await tester.pumpAndSettle();

    expect(find.text('분기 보고서'), findsOneWidget);
    expect(tasks.weekTasks.single.illusion, 10);
  });

  testWidgets('empty title is refused', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byKey(const Key('addTask')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save')));
    await tester.pump();
    expect(find.text('제목을 입력해주세요'), findsOneWidget);
    expect(tasks.tasks, isEmpty);
  });

  testWidgets('swipe deletes and undo restores', (tester) async {
    await pumpHome(tester);
    await tasks.loadSampleData();
    await tester.tap(find.text('목록'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('무한 스크롤'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(tasks.weekTasks, hasLength(3));

    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(tasks.weekTasks, hasLength(4));

    // Two deletes in a row: undo applies to the latest one straight away.
    await tester.drag(find.text('무한 스크롤'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('형식적인 회의'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(tasks.weekTasks.map((t) => t.title), isNot(contains('무한 스크롤')));
    expect(tasks.weekTasks.map((t) => t.title), contains('형식적인 회의'));
  });

  testWidgets('checkbox marks a task done and the summary counts it', (tester) async {
    await pumpHome(tester);
    await tasks.loadSampleData();
    await tester.tap(find.text('목록'));
    await tester.pumpAndSettle();
    expect(find.text('완료 0/4'), findsOneWidget);
    expect(find.text('집중 1'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(tasks.weekTasks.where((t) => t.done), hasLength(1));
    expect(find.text('완료 1/4'), findsOneWidget);
  });

  testWidgets('week arrows move between weeks', (tester) async {
    await pumpHome(tester);
    final start = tasks.selectedWeek;
    expect(find.text('이번 주'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nextWeek')));
    await tester.pumpAndSettle();
    expect(tasks.selectedWeek.difference(start).inDays, 7);
    expect(find.text('다음 주'), findsOneWidget);

    await tester.tap(find.byKey(const Key('prevWeek')));
    await tester.tap(find.byKey(const Key('prevWeek')));
    await tester.pumpAndSettle();
    expect(find.text('지난 주'), findsOneWidget);
  });

  testWidgets('tapping a shared point asks which task to open', (tester) async {
    await pumpHome(tester);
    await tasks.addTask(Task(id: 'a', title: '하나', weekStart: tasks.selectedWeek));
    await tasks.addTask(Task(id: 'b', title: '둘', weekStart: tasks.selectedWeek));
    await tester.pumpAndSettle();

    // Both have the default scores (x = 5, y = 5): three quarters across,
    // one quarter down the graph.
    final graph = tester.getRect(find.byKey(const Key('graph')));
    await tester.tapAt(graph.topLeft + Offset(graph.width * 0.75, graph.height * 0.25));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('둘')));
    await tester.pumpAndSettle();
    expect(find.text('태스크 편집'), findsOneWidget);
    expect(find.widgetWithText(TextField, '둘'), findsOneWidget);
  });

  testWidgets('summary fits a narrow 320px screen', (tester) async {
    await pumpHome(tester);
    tester.view.physicalSize = const Size(320, 640);
    await tasks.loadSampleData();
    await tester.pumpAndSettle();
    expect(find.text('완료 0/4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('export to clipboard, then import into an empty account', (tester) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpHome(tester);
    await tasks.loadSampleData();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('백업 내보내기 (클립보드)'));
    await tester.pumpAndSettle();
    expect(clipboard, contains('"app": "quadranti"'));

    // A different (empty) account imports it.
    await tasks.setUser('other');
    await tester.pumpAndSettle();
    expect(tasks.tasks, isEmpty);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('백업 가져오기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('backupText')), 'nonsense');
    await tester.tap(find.byKey(const Key('importBackup')));
    await tester.pumpAndSettle();
    expect(find.text('백업 형식이 아닙니다 (JSON 아님)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('backupText')), clipboard!);
    await tester.tap(find.byKey(const Key('importBackup')));
    await tester.pumpAndSettle();
    expect(tasks.tasks, hasLength(4));
    expect(find.text('가져오기 완료: 새 태스크 4개, 덮어쓴 태스크 0개'), findsOneWidget);
  });

  testWidgets('banner brings last week\'s unfinished tasks into this week', (tester) async {
    await pumpHome(tester);
    final lastWeek = addWeeks(tasks.selectedWeek, -1);
    await tasks.addTask(Task(id: 'open', title: '미룬 일', weekStart: lastWeek));
    await tasks.addTask(Task(id: 'done', title: '끝낸 일', weekStart: lastWeek, done: true));
    await tester.pumpAndSettle();
    expect(find.text('지난 주에 끝내지 못한 태스크가 1개 있어요'), findsOneWidget);

    // Not shown on other weeks.
    await tester.tap(find.byKey(const Key('prevWeek')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carryOverBanner')), findsNothing);
    await tester.tap(find.byKey(const Key('nextWeek')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('carryOverAccept')));
    await tester.pumpAndSettle();
    expect(tasks.weekTasks.map((t) => t.id), ['open']);
    expect(find.byKey(const Key('carryOverBanner')), findsNothing);
  });

  testWidgets('banner can be closed', (tester) async {
    await pumpHome(tester);
    await tasks.addTask(Task(id: 'open', title: '미룬 일', weekStart: addWeeks(tasks.selectedWeek, -1)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carryOverBanner')), findsNothing);
    expect(tasks.weekTasks, isEmpty);
  });

  testWidgets('guide opens once on first arrival and from the menu', (tester) async {
    final prefs = MemoryPrefs();
    final auth = _FakeAuth();
    Future<void> pump() async {
      tasks = TaskProvider(repositoryFor: (_) => MemoryTaskRepository());
      await tasks.setUser('u');
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<TaskProvider>.value(value: tasks),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        // A new key forces a fresh HomeScreen, as after signing in again.
        child: MaterialApp(home: HomeScreen(key: UniqueKey(), prefs: prefs)),
      ));
      await tester.pumpAndSettle();
    }

    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump();
    expect(find.byType(GuideScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('guideDone')));
    await tester.pumpAndSettle();
    expect(find.byType(GuideScreen), findsNothing);

    await pump();
    expect(find.byType(GuideScreen), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사용법'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideScreen), findsOneWidget);
  });
}
