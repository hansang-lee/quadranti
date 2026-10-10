// Shared driver for the scenario tests: launching the real app on real
// storage, a clock the scenario can move, form helpers and numbered
// screenshots. See docs/testing.md.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:quadranti/main.dart';
import 'package:quadranti/providers/task_provider.dart';
import 'package:quadranti/screens/guide_screen.dart';
import 'package:quadranti/screens/task_editor_screen.dart';

IntegrationTestWidgetsFlutterBinding ensureScenarioBinding() => IntegrationTestWidgetsFlutterBinding.ensureInitialized();

bool _surfaceConverted = false;

/// One scenario run: the tester, a name for the screenshots and the clock
/// the app reads (starts at the real time; [advance] moves it).
class Scenario {
  Scenario(this.tester, this.name) : now = DateTime.now();

  final WidgetTester tester;
  final String name;
  DateTime now;
  int _n = 0;

  /// An email no earlier run has used, so scenarios never collide with
  /// accounts left in storage by a previous run.
  late final String email = 'scenario_${name}_${DateTime.now().microsecondsSinceEpoch}@test.local';

  /// Starts the app the way a cold start does: Hive (re)opened from the
  /// device's storage and fresh providers. With [signedOut] the stored
  /// session is cleared first, so the run begins on the login screen.
  Future<void> launch({bool signedOut = false}) async {
    await tester.pumpWidget(const SizedBox());
    await Hive.close();
    await Hive.initFlutter();
    if (signedOut) await (await Hive.openBox('auth')).clear();
    await tester.pumpWidget(createApp(clock: () => now));
    await settle();
  }

  /// The app's TaskProvider, to read what the screens should show.
  /// (Read from MaterialApp, which is always there, unlike a Scaffold mid-transition.)
  TaskProvider get tasks =>
      Provider.of<TaskProvider>(tester.element(find.byType(MaterialApp, skipOffstage: false)), listen: false);

  /// Moves the clock by [by] and re-runs whatever the app does when a week
  /// is opened (as reopening the app would).
  Future<void> advance(Duration by) async {
    now = now.add(by);
    tasks.selectWeek(now);
    await settle();
  }

  Future<void> signUp({String password = 'pw 1234', String displayName = '테스터'}) async {
    await tap(find.byKey(const Key('toggleSignUp')));
    await enter(find.byKey(const Key('displayName')), displayName);
    await enter(find.byKey(const Key('email')), email);
    await enter(find.byKey(const Key('password')), password);
    await tap(find.byKey(const Key('submit')));
    // A new user lands on the guide, which covers home.
    await waitFor(find.byType(GuideScreen), what: 'the guide after signing up');
  }

  Future<void> signIn({String password = 'pw 1234'}) async {
    await enter(find.byKey(const Key('email')), email);
    await enter(find.byKey(const Key('password')), password);
    await tap(find.byKey(const Key('submit')));
    await waitFor(find.byKey(const Key('addTask')), what: 'the home screen');
  }

  /// Closes the guide that opens on a user's first arrival.
  Future<void> closeGuide() async {
    await waitFor(find.byType(GuideScreen), what: 'the guide');
    // Its button is at the end of a lazy list: scroll until it is built.
    await tester.scrollUntilVisible(
      find.byKey(const Key('guideDone')),
      300,
      scrollable: find.descendant(of: find.byType(GuideScreen), matching: find.byType(Scrollable)).first,
    );
    await tap(find.byKey(const Key('guideDone')));
    await waitGone(find.byType(GuideScreen), what: 'the guide');
  }

  /// Opens the ⋮ menu and picks [item].
  Future<void> menu(String item) async {
    await tap(find.byIcon(Icons.more_vert));
    await tap(find.text(item).last);
  }

  /// Adds a task through the editor. Scores not given keep their defaults.
  Future<void> addTask(String title, {double? effectiveness, double? waste, double? immediacy, double? illusion, bool repeat = false}) async {
    await tap(find.byKey(const Key('addTask')));
    await enter(find.byKey(const Key('title')), title);
    for (final (label, value) in [('효과', effectiveness), ('낭비', waste), ('즉시성', immediacy), ('착각', illusion)]) {
      if (value != null) await setSlider(label, value);
    }
    if (repeat) {
      await reveal(find.byKey(const Key('repeat')));
      await tap(find.byKey(const Key('repeat')));
    }
    await tap(find.byKey(const Key('save')));
    await waitGone(find.byKey(const Key('save')), what: 'the editor');
  }

  /// Brings [finder] into view in the editor. The editor is a lazy list on
  /// a short screen, so a widget far from the current position may not
  /// even be built: go back to the top, then scroll down until it shows.
  Future<void> reveal(Finder finder) async {
    final list = find.descendant(of: find.byType(TaskEditorScreen), matching: find.byType(Scrollable)).first;
    await tester.drag(list, const Offset(0, 3000));
    await settle();
    await tester.scrollUntilVisible(finder, 150, scrollable: list);
    await settle();
  }

  /// Sets the editor's 0-10 slider [label] by tapping its track.
  Future<void> setSlider(String label, double value) async {
    final slider = find.byKey(Key('slider_$label'));
    await reveal(slider);
    final rect = tester.getRect(slider);
    // The track is inset by the thumb's radius at both ends (24 px here).
    const inset = 24.0;
    final x = rect.left + inset + (rect.width - 2 * inset) * value / 10;
    await tester.tapAt(Offset(x, rect.center.dy));
    await settle();
  }

  /// Taps [finder] once it can really be hit: something on top (a
  /// SnackBar, a closing sheet) would otherwise take the tap silently.
  Future<void> tap(Finder finder) async {
    await waitFor(finder.hitTestable(), what: '${finder.describeMatch(Plurality.one)} (hit-testable)');
    await tester.tap(finder.hitTestable().first);
    await settle();
  }

  /// Puts [text] in the field [finder]. On the web the browser's own input
  /// element holds the text too, and `tester.enterText` changes only
  /// Flutter's side: the element's old value comes back as the field loses
  /// focus. There the field's controller is set instead, which Flutter
  /// passes on to the element (the approach cling's scenarios use).
  Future<void> enter(Finder finder, String text) async {
    await waitFor(finder);
    await tester.ensureVisible(finder.first);
    if (!kIsWeb) {
      await tester.enterText(finder.first, text);
    } else {
      await tester.showKeyboard(finder.first);
      final editable = tester.state<EditableTextState>(
          find.descendant(of: finder.first, matching: find.byType(EditableText), matchRoot: true));
      editable.widget.controller.value =
          TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
      await tester.pump();
    }
    await settle();
  }

  /// Saves what the screen shows now as the next numbered step.
  Future<void> shot(String step) async {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    // Android draws into a surface the test cannot read until it is
    // converted to an image, once per run. Web needs nothing.
    if (!kIsWeb && !_surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      _surfaceConverted = true;
    }
    await tester.pump(const Duration(milliseconds: 300));
    _n++;
    await binding.takeScreenshot('${name}_${_n.toString().padLeft(2, '0')}_$step');
  }

  /// Pumps real frames until [finder] finds something, or fails after
  /// [timeout].
  Future<void> waitFor(Finder finder, {Duration timeout = const Duration(seconds: 15), String? what}) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        // What the screen showed instead is usually the answer.
        await shot('TIMEOUT');
        throw TestFailure('Timed out after ${timeout.inSeconds}s waiting for ${what ?? finder.describeMatch(Plurality.one)}');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitGone(Finder finder, {Duration timeout = const Duration(seconds: 15), String? what}) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(end)) {
        await shot('TIMEOUT');
        throw TestFailure('Timed out after ${timeout.inSeconds}s waiting for ${what ?? finder} to go');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Lets animations finish without failing on one that never stops.
  Future<void> settle([Duration max = const Duration(seconds: 3)]) async {
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, max);
    } on FlutterError {
      // Something keeps animating (a spinner); carry on with real frames.
    }
  }
}
