// A backup moves tasks and their repeat rule to another account through the
// clipboard (the file dialogs are system screens; widget tests cover them).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scenario.dart';

void main() {
  ensureScenarioBinding();

  testWidgets('backup', (tester) async {
    final s = Scenario(tester, 'backup');
    await s.launch(signedOut: true);
    await s.signUp();
    await s.closeGuide();
    await s.tap(find.byKey(const Key('loadSamples')));
    await s.addTask('매주 할 일', repeat: true);

    await s.menu('백업');
    await s.shot('backup_sheet');
    await s.tap(find.byKey(const Key('backupCopy')));
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    expect(text, contains('"app": "quadranti"'));
    expect(text, contains('"repeats"'));

    await s.menu('로그아웃 (테스터)');
    final other = Scenario(tester, 'backup_other')..now = s.now;
    await other.signUp(displayName: '새 기기');
    await other.closeGuide();
    await other.menu('백업');
    await other.tap(find.byKey(const Key('backupPaste')));
    await other.enter(find.byKey(const Key('backupText')), text!);
    await other.shot('paste');
    await other.tap(find.byKey(const Key('importBackup')));
    expect(find.text('가져오기 완료: 새 태스크 5개, 덮어쓴 태스크 0개'), findsOneWidget);
    expect(other.tasks.weekTasks, hasLength(5));
    expect(other.tasks.rules, hasLength(1));
    await other.shot('imported');
  });
}
