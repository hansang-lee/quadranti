import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quadranti/models/user_model.dart';
import 'package:quadranti/providers/auth_provider.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/screens/home_screen.dart';
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
    await pumpHome(tester);
    expect(find.text('이 주에 등록된 태스크가 없습니다'), findsOneWidget);

    await tester.tap(find.byKey(const Key('loadSamples')));
    await tester.pumpAndSettle();
    expect(tasks.weekTasks, hasLength(4));
    expect(find.byKey(const Key('graph')), findsOneWidget);
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
  });

  testWidgets('checkbox marks a task done', (tester) async {
    await pumpHome(tester);
    await tasks.loadSampleData();
    await tester.tap(find.text('목록'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(tasks.weekTasks.where((t) => t.done), hasLength(1));
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
}
