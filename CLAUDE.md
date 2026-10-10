# Working on Quadranti

Start here, then read `docs/plan.md`.

## What this is

Quadranti is a weekly scheduler. Each task is rated on four properties
(effectiveness, waste, immediacy, illusion) and placed on a value ×
real-urgency graph. Its quadrant (집중, 주의, 제거, 계획) says how to treat it.
It is a Flutter app for web and Android, with Provider for state and Hive
(`hive_ce`) for storage that stays on the device. There is no server.

The repository is **public**, and every green push to `master` deploys the web
build to https://hansang-lee.github.io/quadranti/ (`.github/workflows/ci.yml`).
Anything pushed is therefore live within minutes, and nothing secret may be
committed.

## Where things are written down

| Document | What it answers |
|---|---|
| `docs/README.md` | The index of every document, and the conventions for naming, placing and writing them |
| `docs/plan.md` | **Read first.** The current state and the open tasks by phase |
| `docs/history.md` | Finished tasks, verbatim and by phase. A task id no longer in the plan is here |
| `docs/decisions.md` | The decision table (D1, D2, …): every decision made or still open, with its date |
| `docs/concept.md` | The model: the four properties, the axis formula and the quadrants |
| `docs/development.md` | The toolchain, running the app, the code layout and conventions, and screenshots of the web build |
| `scripts/README.md` | Every script, its usage, and the `out/` layout |

Keep these current as part of the work, not afterwards. A task is finished
when its plan entry is ticked and moved to `docs/history.md`, and the affected
document says what the code now does.

## How we work

- **One commit per finished unit of work**, pushed straight away. Commit
  messages say *why*, not just what.
- **Plan-driven.** Work follows `docs/plan.md`. New problems found along the
  way get a numbered task in the plan, not a silent fix or a forgotten note.
- **Decisions go in `docs/decisions.md`**, with the date. Rows marked
  **Open** belong to the owner. In particular, D1 (the axis formula) and D4
  (the local login) are not changed without the owner.
- **Verify before claiming.** Run the checks, and look at the real screen
  where it matters (`docs/development.md`, "Looking at the UI"). Say plainly
  what was not verified.
- Risky changes (stored data formats, the repeat rules, auth, deleting data)
  get a separate review before they are called done.
- The UI is in Korean. Code, comments, docs, commit messages and script
  output are in English. Answer the owner in Korean.

## Running and checking

```bash
scripts/web.sh              # web dev server on http://localhost:8000
scripts/test/check.sh       # analyze + unit/widget tests; push only on "All checks passed."
scripts/screens.sh <steps>  # screenshots of the real web build (docs/development.md)
flutter build apk --debug   # local Android SDK
```

Every script is in `scripts/` and listed with its usage in
`scripts/README.md`; a new script gets a row there. Runs leave their logs,
screenshots and a `summary.txt` in `out/<YYMMDD_hhmmss>/` (gitignored, the
newest 30 kept), so repeated work goes through the scripts and its results
land in one place. CI runs `check.sh` and the web build on every push and
pull request, then deploys from `master`. The repository is public, so
Actions minutes are free.

## Things that bite

- **`TaskProvider` never mutates a list in place.** Every change assigns a new
  unmodifiable list. `QuadrantPainter.shouldRepaint` and the `weekTasks` cache
  compare lists by identity, so an in-place change is never drawn.
- **Batch writes capture the repository first** (`_putAll`, and
  `createDueRepeats`). A user switch in the middle must not send the
  remaining writes to the next user's box.
- **Dates are built from calendar fields**, as in `DateTime(y, m, d + n)`,
  never by adding a `Duration`. Weeks are Mondays (`core/week.dart`), and
  storage uses `yyyy-MM-dd`.
- **Stored formats only grow.** `Task.fromMap` and `RepeatRule.fromMap` must
  read older records, so a new field needs a default. The backup has a
  version (`TaskBackup.version`), and older versions must still import.
- **Repeat rules (D10)** create one instance per calendar week with the id
  `<rule>-<yyyy-MM-dd>`. Only the newest instance updates the template.
  Read D10 before touching `createDueRepeats` or `setRepeat`.
- **Fonts.** Canvas text (`QuadrantPainter`) and explicit `TextStyle`s in the
  theme must set `AppTheme.fontFamily`, or they fall back to the system face.
  Only weights 400 and 700 are bundled (D6).
- **`docs/concept.md` and `lib/screens/guide_screen.dart` say the same
  thing** in two languages. Change them together.
- **Snackbars** call `hideCurrentSnackBar()` before `showSnackBar`.
  Otherwise they queue, and undo acts on the wrong task.
- **Never run `dart format` over `lib/` or `test/`.** The code is at about
  120 columns, and the formatter rewrites unrelated lines. Format only the
  lines you touched.
- **Widget tests** use a tall phone-sized view (`tester.view.physicalSize`),
  because the editor is a lazy `ListView`. A `SemanticsHandle` must be
  disposed inside the test body, not in `addTearDown`.
- **`flutter test | tail -1` can hide failures.** Look for "All tests
  passed!".
- **Shell.** The shell is zsh, which does not word-split unquoted variables,
  so pipe file lists through `xargs`. `pkill -f <pattern>` also matches the
  shell running it and kills it (exit 144), so kill by PID instead.
