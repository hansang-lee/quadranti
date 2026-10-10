// Do the screens fit every kind of phone? Device differences that matter to
// a Flutter app come down to a few numbers (docs/testing.md, "Devices"):
// the screen size, the system bars over the app (Android 15+ draws edge to
// edge), the keyboard, and the user's text size. Each profile below is one
// combination of those; every screen is drawn with the real bundled font,
// scrolled through, and its main action must be on screen, clear of the
// system bars and tappable. A RenderFlex overflow fails a test on its own.
// Same approach as cling's app/test/screen_fit_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quadranti/core/theme.dart';
import 'package:quadranti/core/week.dart';
import 'package:quadranti/models/task_model.dart';
import 'package:quadranti/models/user_model.dart';
import 'package:quadranti/providers/auth_provider.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/screens/guide_screen.dart';
import 'package:quadranti/screens/home_screen.dart';
import 'package:quadranti/screens/login_screen.dart';
import 'package:quadranti/screens/task_editor_screen.dart';
import 'package:quadranti/services/task_repository.dart';

class Profile {
  const Profile(this.name, this.size, {this.top = 24, this.bottom = 0, this.textScale = 1.0});
  final String name;
  final Size size; // dp; the keyboard is modelled as a shorter screen
  final double top; // status bar
  final double bottom; // navigation bar (48 dp with buttons, 24 dp gesture)
  final double textScale;
}

const profiles = [
  Profile('small 320x568, buttons', Size(320, 568), bottom: 48),
  Profile('galaxy 360x780, buttons, text 130%', Size(360, 780), bottom: 48, textScale: 1.3),
  Profile('360 with the keyboard up', Size(360, 400), bottom: 0),
  Profile('ultra 412x915, gesture bar', Size(412, 915), bottom: 24),
  Profile('fold open 690x840, gesture bar', Size(690, 840), bottom: 24),
  Profile('large text 360x740, 200%', Size(360, 740), bottom: 48, textScale: 2.0),
];

Future<void> loadAppFont() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final f in ['IBMPlexSansKR-Regular.ttf', 'IBMPlexSansKR-Bold.ttf']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

void apply(WidgetTester tester, Profile p) {
  tester.view.physicalSize = p.size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: p.top, bottom: p.bottom);
  tester.view.viewPadding = FakeViewPadding(top: p.top, bottom: p.bottom);
  tester.platformDispatcher.textScaleFactorTestValue = p.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

class _FakeAuth extends AuthProvider {
  @override
  User? get currentUser => User(id: 'u', email: 'u@x.com', displayName: '아주긴이름의테스터');
}

late TaskProvider tasks;

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tasks = TaskProvider(repositoryFor: (_) => MemoryTaskRepository());
  await tasks.setUser('u');
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<TaskProvider>.value(value: tasks),
      ChangeNotifierProvider<AuthProvider>.value(value: _FakeAuth()),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
  ));
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox()));
}

/// Scrolls every vertical list to its end, so lazily built rows are laid
/// out (and would report an overflow) too.
Future<void> scrollThrough(WidgetTester tester) async {
  final lists = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  for (var i = 0; i < lists.evaluate().length; i++) {
    for (var step = 0; step < 8; step++) {
      await tester.drag(lists.at(i), const Offset(0, -400), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  }
}

/// [finder] can be brought on screen, lies clear of the system bars and
/// takes a tap.
Future<void> expectReachable(WidgetTester tester, Profile p, Finder finder) async {
  final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  if (finder.evaluate().isEmpty && list.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(finder, 200, scrollable: list.last);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(p.top - 0.5), reason: '$finder under the status bar: $rect');
  expect(rect.bottom, lessThanOrEqualTo(p.size.height - p.bottom + 0.5), reason: '$finder under the navigation bar: $rect');
  expect(finder.hitTestable(), findsOneWidget, reason: '$finder is covered');
}

Future<void> addLongTasks() async {
  final week = weekStartOf(tasks.now());
  for (var i = 0; i < 12; i++) {
    await tasks.addTask(Task(
      id: 'long$i',
      title: '아주 긴 제목의 태스크 $i번: 다음 분기 전략 보고서 초안 검토와 피드백 반영',
      description: '메모도 길게 적어 둔 경우를 확인합니다. ' * 3,
      immediacy: (i % 11).toDouble(),
      effectiveness: (10 - i % 11).toDouble(),
      waste: (i % 3).toDouble(),
      illusion: (i % 4).toDouble(),
      weekStart: week,
      done: i.isEven,
    ));
  }
}

void main() {
  setUpAll(loadAppFont);

  for (final p in profiles) {
    group(p.name, () {
      testWidgets('login and sign-up', (tester) async {
        apply(tester, p);
        await pumpScreen(tester, const LoginScreen());
        // The profile's text size really reaches the screens.
        final context = tester.element(find.byType(LoginScreen));
        expect(MediaQuery.textScalerOf(context).scale(10), closeTo(10 * p.textScale, 0.01));
        await expectReachable(tester, p, find.byKey(const Key('submit')));
        await tester.tap(find.byKey(const Key('toggleSignUp')));
        await tester.pumpAndSettle();
        await scrollThrough(tester);
        await expectReachable(tester, p, find.byKey(const Key('submit')));
      });

      testWidgets('home: empty week', (tester) async {
        apply(tester, p);
        await pumpScreen(tester, const HomeScreen());
        await expectReachable(tester, p, find.byKey(const Key('loadSamples')));
        await expectReachable(tester, p, find.byKey(const Key('addTask')));
      });

      testWidgets('home: graph and list full of long tasks, with the banner', (tester) async {
        apply(tester, p);
        await pumpScreen(tester, const HomeScreen());
        await tasks.addTask(Task(id: 'last', title: '지난 주 일', weekStart: addWeeks(weekStartOf(tasks.now()), -1)));
        await addLongTasks();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('carryOverBanner')), findsOneWidget);
        final graph = tester.getRect(find.byKey(const Key('graph')));
        expect(graph.overlaps(tester.getRect(find.byKey(const Key('addTask')))), isFalse);
        await tester.tap(find.text('목록'));
        await tester.pumpAndSettle();
        await scrollThrough(tester);
        await expectReachable(tester, p, find.byKey(const Key('addTask')));
      });

      testWidgets('task editor', (tester) async {
        apply(tester, p);
        await pumpScreen(tester, const TaskEditorScreen());
        await scrollThrough(tester);
        await expectReachable(tester, p, find.byKey(const Key('slider_착각')));
        await expectReachable(tester, p, find.byKey(const Key('save')));
      });

      testWidgets('guide', (tester) async {
        apply(tester, p);
        await pumpScreen(tester, const GuideScreen());
        await scrollThrough(tester);
        await expectReachable(tester, p, find.byKey(const Key('guideDone')));
      });

      testWidgets('backup sheet and paste dialog', (tester) async {
        apply(tester, p);
        await pumpScreen(tester, const HomeScreen());
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('백업'));
        await tester.pumpAndSettle();
        await expectReachable(tester, p, find.byKey(const Key('backupPaste')));
        await tester.tap(find.byKey(const Key('backupPaste')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('backupText')), List.filled(30, '{"line": 1},').join('\n'));
        await tester.pumpAndSettle();
        await expectReachable(tester, p, find.byKey(const Key('importBackup')));
      });
    });
  }
}
