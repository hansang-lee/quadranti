# Testing Quadranti

This document covers what is tested, where, how to run it, and what is
missing. It follows cling's `docs/testing.md`. It was written 2026-10-10,
when the scenario tests landed. Keep it current when a layer changes.

## The two layers

| Layer | What it checks | Where | Size | Time | Runs in |
|---|---|---|---|---|---|
| **Unit and widget tests** | The model, week maths, the provider (including races and user switches), Hive storage, local auth, backups, the painter, every screen flow with in-memory storage, and every screen in six device profiles (`screen_fit_test.dart`) | `test/` | 122 tests in 12 files | about 8 s | `scripts/test/check.sh`; CI on every push |
| **Scenario tests** | The real app on real storage (Hive on Android, IndexedDB on web), real fonts and a real screen size: whole user journeys with a screenshot per step | `integration_test/` | 6 scenarios | about 3 min on the emulator, about 5 min in local Chrome, about 7 min in CI | `scripts/test/scenario.sh` (emulator) or `--web`; CI runs `--web` on every push |

The layers split the work on purpose. Combinations and edge cases (every
repeat rule, every malformed backup, user switches mid-write) live in the
fast layer. The scenarios prove that the pieces work together on a device,
with one journey per feature. They catch what only a real screen shows, such
as the keyboard, a 360 dp phone and storage across a restart. They do not
repeat the fast layer's cases.

In Korean these are 위젯 테스트 and 시나리오 테스트.

**What the scenarios found on their first runs (2026-10-10).**

- The empty week overflowed on a small phone with the keyboard up.
- The backup paste dialog overflowed over its own buttons.
- A snackbar outlived sign-out and covered the next user's guide button.
- In a browser, copying to the clipboard could fail without any message.

Each fix came with a widget test that fails without it.

## Running them

```bash
scripts/test/check.sh                     # analyze + unit/widget tests (what CI runs first)
flutter test test/repeat_test.dart        # one file
flutter test --plain-name 'missed weeks'  # one test by name

scripts/test/scenario.sh                  # all six on the cling_e2e emulator (booted headless if needed)
scripts/test/scenario.sh repeat backup    # some, by file name
scripts/test/scenario.sh --web            # all six in headless Chrome (chromedriver fetched once)
scripts/test/scenario.sh --web --show     # in a visible Chrome window
scripts/test/scenario.sh --matrix         # all six on Android 9, 13 and 16, one emulator at a time (before a release)
```

Results go to `out/<YYMMDD_hhmmss>/` (gitignored, newest 30 kept):

```
out/261010_130151/
  summary.txt                 PASS/FAIL per check or scenario, then the result
  app/                        check.sh: analyze.log, test.log
  scenarios/logs/<name>.log   flutter drive output per scenario
  scenarios/screenshots/      <scenario>_<nn>_<step>.png; <..>_TIMEOUT.png when a wait gave up
  scenarios/chromedriver.log  --web only
  scenarios/<avd>/            --matrix: the same per AVD (logs/, screenshots/, summary.txt, emulator.log)
```

CI keeps `out/` as the `scenarios` artifact on every run, with screenshots
included. A failed check also keeps its `out/` as the `out` artifact.

## The scenarios

| Scenario | Journey | Checks in particular |
|---|---|---|
| `first_run` | Sign up, read the guide, see the empty week, load the samples, view the graph and the list | The guide opens once on arrival; one sample per quadrant |
| `task_lifecycle` | Add a task with sliders, open it from its dot on the graph, re-rate it, tick it done, swipe-delete and undo | The editor's live quadrant card; saved scores equal the slider positions; graph hit-testing |
| `persistence` | Add and tick a task, cold-start the app, then switch to another account and back | The session and the task (scores, done) survive a restart; a second account sees nothing |
| `week_flow` | Step to next week and back, then let a week pass and accept the carry-over banner | The 이번 주 / 다음 주 labels; the banner moves only the unfinished task |
| `repeat` | Make a weekly task, cold-start a week later, then turn repeat off and let another week pass | One fresh open copy per week (D10); nothing after stopping |
| `backup` | Load samples plus a weekly task, copy the backup, sign up a second account and paste it | Tasks and the repeat rule arrive (version 2); copy failure is reported on web |

## Devices

Phone models and Android versions are not tested one by one, and there are
no per-version tests. The owner asked this for cling and quadranti on
2026-10-10, and both answer it the same way. Flutter draws every pixel
itself and ships its own font, so a Galaxy and a Pixel show the same
widgets. What differs reaches the app as a few numbers, and each of them is
tested where it is cheapest:

| What differs | Where it is tested |
|---|---|
| Screen size, from 320 dp phones to an open fold | `screen_fit_test.dart`, six profiles |
| System bars over the app: the status bar, a 48 dp button bar or a 24 dp gesture bar (Android 15+ draws edge to edge) | `screen_fit_test.dart` (the main action must clear the bars), `system_insets_test.dart` |
| The keyboard taking half the screen | `screen_fit_test.dart` (a 360x400 profile), plus every scenario that types |
| The user's text size (130 %, 200 %) | `screen_fit_test.dart` |
| Android version behaviour: edge to edge, permissions, file dialogs, storage | `scenario.sh --matrix` on Android 9, 13 and 16, before a release |
| Samsung's own behaviour and the real hardware | The owner's phone (`scripts/phone.sh`), the release checklist, and Google Play's pre-launch report (PLAN 5.5, 5.6) |

`screen_fit_test.dart` draws every screen (login, empty week, graph and list
full of long tasks with the carry-over banner, editor, guide, backup sheet
and paste dialog) with the real bundled font, in each profile. It scrolls
each list to the end, and requires the screen's main action to be on
screen, clear of the system bars and tappable. A layout overflow fails the
test by itself. A new screen gets a test in each profile, which is one
`testWidgets` in the loop.

**The matrix AVDs** are cling's (`cling_api28`, `cling_api33`,
`cling_api36`). Like `cling_e2e`, they are shared, because the system images
take several GB and the apps do not clash. Each is a `small_phone`
(360x640 dp) on a `google_apis` x86_64 image with 2 GB of RAM. If they are
missing, create them like this:

```bash
SDK=~/Android/Sdk
for api in 28 33 36; do
  $SDK/cmdline-tools/latest/bin/sdkmanager "system-images;android-$api;google_apis;x86_64"
  echo no | $SDK/cmdline-tools/latest/bin/avdmanager create avd -n cling_api$api \
    -k "system-images;android-$api;google_apis;x86_64" -d small_phone
  echo 'hw.ramSize=2048' >> ~/.android/avd/cling_api$api.avd/config.ini
done
```

`--matrix` stops every running emulator first, and it checks that all its
AVDs exist before stopping anything. Do not start it while another scenario
run, this project's or cling's, is using an emulator. It boots `cling_e2e`
again at the end if that was running before.

## How the scenarios are built

`integration_test/support/scenario.dart` holds one `Scenario` per test:

- `launch({signedOut})` starts the app the way a cold start does: Hive
  reopened from the device's storage and fresh providers from
  `createApp(clock:)`. `signedOut` clears the stored session first. Calling
  it again in the middle of a scenario is a restart.
- `now` is the clock the whole app reads (`TaskProvider.now()`). Setting it
  and relaunching, or calling `advance(duration)`, moves the app to another
  week. This is how `week_flow` and `repeat` cover a week passing.
- Every scenario signs up a new account (`scenario_<name>_<µs>@test.local`),
  so runs never collide with data left on the device by earlier runs.
- `tap` waits until its target is hit-testable, because a snackbar or a
  closing sheet would otherwise take the tap silently. `reveal` scrolls the
  editor (a lazy list) back to the top and down to a widget. `setSlider`
  taps a slider's track at the value's position. `enter` sets the field's
  controller on web (see "Things that bite").
- `shot(step)` saves `<name>_<nn>_<step>.png` through the driver
  (`test_driver/integration_test.dart`, `SCENARIO_SHOTS_DIR`). A wait that
  times out saves a `TIMEOUT` shot first.

## Things that bite

- **Lazy lists.** The guide and the editor build only what is near the
  viewport, so a finder for a widget further down finds nothing. Use
  `reveal`, or `scrollUntilVisible` with the screen's own `Scrollable`.
- **Text entry on web.** `tester.enterText` changes only Flutter's side of
  a browser input, and the old value comes back on blur. `Scenario.enter`
  sets the controller instead, as cling does.
- **Clipboard on web.** Headless Chrome refuses clipboard writes and reads
  from scripts. The app reports the failed copy. The backup scenario reads
  the clipboard where it can and otherwise uses the same encoding of the
  same state.
- **The emulator is shared with cling** (`cling_e2e`). The apps differ, so
  runs do not clash. `scenario.sh` only ever targets an `emulator-*` serial,
  never a phone.
- **On web, failure details are not in the log.** The result line shows
  only the method name. Look at the screenshots, where a `TIMEOUT` shot
  usually explains it, or run that scenario on the emulator, whose log has
  the full exception.

## Backlog

- File backup and restore through the system dialogs. These are not
  automatable here, so widget tests cover the app side through the
  `BackupFiles` seam.
- The matrix has not run yet: it waits for cling's matrix AVDs, which are
  being created in cling's session (2026-10-10).
- Korean text wraps between any two syllables (seen at 200 % text). cling
  solved this with `ProseText`; see PLAN 3.12.
- Dark mode in a scenario (`scheme:dark` is covered by `scripts/screens.sh`
  only).
