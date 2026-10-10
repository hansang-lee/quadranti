import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/screens/guide_screen.dart';
import 'package:quadranti/screens/task_editor_screen.dart';
import 'package:quadranti/services/task_repository.dart';

// Android 15+ draws apps edge to edge: the system navigation bar (Galaxy's
// ||| ○ < buttons) lies over the bottom of the screen. A ListView with an
// explicit padding does not add that inset by itself, so its last item
// ended up under the bar (the guide's 시작하기 button on the owner's phone).
void main() {
  const navBar = 48.0;

  Future<void> pump(WidgetTester tester, Widget screen, {double height = 860}) async {
    tester.view.physicalSize = Size(412, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: navBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBar);
    addTearDown(tester.view.reset);
    final tasks = TaskProvider(repositoryFor: (_) => MemoryTaskRepository());
    await tasks.setUser('u');
    await tester.pumpWidget(ChangeNotifierProvider.value(value: tasks, child: MaterialApp(home: screen)));
    await tester.pumpAndSettle();
  }

  Future<void> expectClearOfNavBar(WidgetTester tester, Finder last, {double height = 860}) async {
    await tester.scrollUntilVisible(last, 300, scrollable: find.byType(Scrollable).first);
    // Scroll to the very end, as far as the list goes.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.getRect(last).bottom, lessThanOrEqualTo(height - navBar));
  }

  testWidgets('the guide\'s 시작하기 button stays above the navigation bar', (tester) async {
    await pump(tester, const GuideScreen());
    await expectClearOfNavBar(tester, find.byKey(const Key('guideDone')));
  });

  testWidgets('the editor\'s last slider stays above the navigation bar', (tester) async {
    // A smaller phone, where the editor has to scroll.
    await pump(tester, const TaskEditorScreen(), height: 600);
    await expectClearOfNavBar(tester, find.byKey(const Key('slider_착각')), height: 600);
  });
}
