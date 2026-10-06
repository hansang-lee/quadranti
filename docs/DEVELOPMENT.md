# Development

## Toolchain

- Flutter **3.47.5** stable (Dart 3.13). The version is pinned in
  `.github/workflows/ci.yml` and in the `Dockerfile`, so change both together.
- The local install is at `/home/hslee/development/flutter`, already on PATH.
- The Docker dev container is optional: `./docker.sh` gives a shell, and
  `./docker.sh flutter test` runs one command.

## Run

```bash
./serve.sh                  # web dev server on http://localhost:8000 (PORT=... to change)
flutter run -d chrome       # with hot reload in a local Chrome
flutter run -d <device>     # Android (adb devices)
```

The first screen is the local login. Use 회원가입 to create any account.
Accounts and tasks live in the browser's IndexedDB on web, or in app storage on
Android (D3, D4).

## Check

```bash
flutter analyze             # must be clean (CI fails on any issue)
flutter test                # unit + widget tests, ~3 s
flutter build web --release # CI also builds this
```

CI (`.github/workflows/ci.yml`) runs all three on every push to `master`.

## Layout

```
lib/
  main.dart                  creates AuthProvider + TaskProvider; auth changes call tasks.setUser
  core/                      constants, theme, week helpers (week.dart, week_format.dart), quadrant colours/advice
  models/task_model.dart     Task (immutable, toMap/fromMap), Quadrant enum, the axis formula
  models/user_model.dart     User
  providers/                 AuthProvider, TaskProvider (state for the selected week; writes go through TaskRepository)
  services/                  AuthService + LocalAuthService (Hive), TaskRepository + Hive/Memory implementations
  screens/                   login, home (week bar, menu, FAB), graph_view, list_view, task_editor_screen
  widgets/                   QuadrantPainter (drawing, groupByPosition, tasksAt hit test), EmptyWeek
test/                        one file per unit; app_flow_test.dart drives HomeScreen end to end
tool/web_driver.ts           headless-Chrome driver for screenshots (below)
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
- Widget tests use a tall phone-sized view (`tester.view.physicalSize`).
  The editor is a lazy `ListView`, so widgets below the fold are not built in
  the default 800x600 test view.

## Looking at the UI (agents)

There is no emulator here. To see real screens, serve the release web build
and drive a headless Chrome:

```bash
flutter build web --release
python3 -m http.server 8765 -d build/web &
google-chrome --headless=new --remote-debugging-port=9333 \
  --user-data-dir=/tmp/quadranti-chrome --window-size=412,860 about:blank &
SHOTS=/tmp/shots bun tool/web_driver.ts goto:http://localhost:8765/ wait:3000 shot:login
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

The Chrome profile directory keeps IndexedDB between runs. Delete it to
start again from a blank state.
