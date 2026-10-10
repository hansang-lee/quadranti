# Development

## Toolchain

- Flutter **3.47.5** stable (Dart 3.13). The version is pinned in
  `.github/workflows/ci.yml` and in the `Dockerfile`, so change both together.
- The local install is at `/home/hslee/development/flutter`, already on PATH.
- The Docker dev container is optional: `scripts/docker.sh` gives a shell, and
  `scripts/docker.sh flutter test` runs one command.

## Run

```bash
scripts/web.sh              # web dev server on http://localhost:8000 (PORT=... to change)
flutter run -d chrome       # with hot reload in a local Chrome
flutter run -d <device>     # Android (adb devices)
```

The first screen is the local login. Use 회원가입 to create any account.
Accounts and tasks live in the browser's IndexedDB on web, or in app storage on
Android (D3, D4).

## Check

```bash
scripts/test/check.sh       # analyze + unit/widget tests, logs in out/<run>/; "All checks passed."
scripts/test/check.sh --build   # and the release web build, as CI does
flutter test test/repeat_test.dart --plain-name 'missed weeks'   # one file or test
flutter build apk --debug   # local Android SDK at ~/Android/Sdk; ~1 min (not in CI)
```

CI (`.github/workflows/ci.yml`) runs `check.sh` and the web build on every
push and pull request, then deploys `master` to GitHub Pages. Every script
and the `out/` layout are described in `scripts/README.md`.

## Layout

```
lib/
  main.dart                  creates AuthProvider + TaskProvider; auth changes call tasks.setUser
  core/                      constants, theme, week helpers (week.dart, week_format.dart), quadrant colours/advice
  models/task_model.dart     Task (immutable, toMap/fromMap), Quadrant enum, the axis formula
  models/repeat_rule.dart    RepeatRule (weekly repeat template + lastWeek, D10)
  models/user_model.dart     User
  providers/                 AuthProvider, TaskProvider (state for the selected week; writes go through TaskRepository)
  services/                  AuthService + LocalAuthService (Hive), TaskRepository + Hive/Memory implementations
                             (tasks and repeat rules), TaskBackup (JSON v2), BackupFiles (file_picker seam), Prefs
  screens/                   login, home (week bar, menu, FAB), graph_view, list_view, task_editor_screen
  widgets/                   QuadrantPainter (drawing, groupByPosition, tasksAt hit test), EmptyWeek
test/                        unit + widget tests, one file per unit; app_flow_test.dart drives HomeScreen end to end
integration_test/            scenario tests (docs/testing.md); support/scenario.dart is their driver
test_driver/                 flutter drive's host side: saves the scenario screenshots
scripts/                     web.sh, docker.sh, screens.sh + web_driver.ts, test/check.sh; see scripts/README.md
out/                         run results (gitignored), one folder per run
```

Conventions:

- `TaskProvider` never mutates a list in place. Every change assigns a new
  unmodifiable list. `QuadrantPainter.shouldRepaint` compares lists by
  identity, and so does the `weekTasks` cache.
- Dates are local dates without a time part, built from calendar fields
  (`DateTime(y, m, d + n)`), never by adding a `Duration` (see `core/week.dart`).
  Storage uses `yyyy-MM-dd`.
- The stored task format is `Task.toMap`. `fromMap` must keep reading older
  records, so a new field needs a default.
- `TaskProvider` batch operations (import, carry-over, samples) update
  memory once and then write through `_putAll`, which captures the
  repository first. A user switch mid-write must not redirect the writes.
- Widget tests use a tall phone-sized view (`tester.view.physicalSize`).
  The editor is a lazy `ListView`, so widgets below the fold are not built in
  the default 800x600 test view.

## Looking at the UI (agents)

To see real screens, run the release web build in a headless Chrome. One
command builds, serves, drives and cleans up, and leaves the PNGs in
`out/<run>/screens/`:

```bash
scripts/screens.sh goto:http://localhost:8765/ wait:3000 shot:login
# Keep accounts and tasks between runs, skip the rebuild:
scripts/screens.sh --no-build --profile /tmp/q-profile goto:http://localhost:8765/ wait:3000 shot:home
```

Then read the PNG. Flutter web draws on a canvas, so click by coordinates
taken from the previous screenshot. Text goes into the focused field with
`type:`. Positions at 412x860 when this was written:

- Login: the signup toggle is at (206, 551). After toggling, the fields are
  name (206, 337), email (206, 397) and password (206, 457), and the submit
  button is at (206, 525).
- Home: the 목록 tab is at (308, 830), the FAB at (368, 758), the menu at
  (391, 28), and 예시 태스크 불러오기 on an empty week at (206, 499).
- Editor: save is at (383, 28), and the sliders are at y ≈ 360 / 452 / 544 / 636
  (효과, 낭비, 즉시성, 착각), from x = 42 to x = 370.

Put `scheme:dark` before `goto:` to see dark mode. Without `--profile`, every
run starts from an empty browser (no accounts). A `--profile` directory keeps
IndexedDB between runs; delete it to start again from a blank state.
