# Decisions

One row per decision. **Open** rows need the owner; everything else was
decided with a stated default and can be revisited. Add new rows at the end,
and never renumber them.

| ID | Date | Status | Decision |
|---|---|---|---|
| D1 | 2026-10-07 | **Open** | Axis formula. See below. |
| D2 | 2026-10-07 | Default | A task belongs to one **week** (Monday to Sunday, `Task.weekStart`), not to a day or time slot. Unfinished tasks move to the next week only when the user asks (menu → 미완료를 다음 주로). |
| D3 | 2026-10-07 | Default | Storage is **local only**: one Hive box per user, `tasks_<userId>`, with tasks stored as plain maps (`Task.toMap`), not generated adapters. There is no sync or backup yet. |
| D4 | 2026-10-07 | **Open** | Keep or drop the **local email login**. See below. |
| D5 | 2026-10-07 | Default | `hive_ce` instead of `hive`. It is the maintained fork, with the same API and file format. |
| D6 | 2026-10-07 | Default | Fonts are bundled, not fetched: IBM Plex Sans KR Regular and Bold in `assets/fonts` (OFL), declared in `pubspec.yaml`, with `google_fonts` removed. `google_fonts` made one family per weight, so a missing weight failed instead of falling back. Only 400 and 700 ship (about 2.8 MB each); w500 and w600 resolve to the nearest of the two. Canvas text (`QuadrantPainter`) and explicit `TextStyle`s in the theme must set `AppTheme.fontFamily` themselves. |
| D7 | 2026-10-07 | Default | The app UI is in Korean. Code, comments, docs and commit messages are in English. |
| D8 | 2026-10-07 | Default | Platforms are **web and Android**. iOS is added when there is a Mac to build on. |
| D9 | 2026-10-07 | Default | Sample tasks are never seeded on their own. An empty week shows a button that adds them. |
| D10 | 2026-10-07 | Default | Repeating tasks are **weekly only**. Each rule (`RepeatRule`, box `repeats_<userId>`) holds a task template and `lastWeek`. When the real calendar week is later than `lastWeek`, it creates one open instance for that week, with the id `<rule id>-<yyyy-MM-dd>`. Missed weeks are not back-filled. Turning repeat on never creates a copy right away: the first new instance comes with the next calendar week after the later of the task's week, the current week and the series' newest week. Only the newest instance (week >= `lastWeek`) updates the template, so ticking or editing an older week does not roll the series back. Deleting an instance leaves the series running, and switching off 매주 반복 deletes the rule but keeps the instances. Carry-over skips a repeating task when its series is already in the target week. Backups are at version 2 and carry the rules; version 1 is still read. |

## D1: axis formula (open)

The formula is now `x = effectiveness - waste` and `y = immediacy - illusion`.
A task with no waste and no illusion can never leave the 집중 quadrant, however
low its effectiveness or immediacy (see `CONCEPT.md`, "Known weakness").

- **A. Keep it.** The negative property is how a task moves down or left.
  This is simple, but the user must always rate both sides.
- **B. Measure from the midpoint.** For example, `x = (effectiveness - 5) - waste / 2`
  and `y = (immediacy - 5) - illusion / 2`, rescaled to -10..10. A task rated low
  on effectiveness then counts as low value by itself, and waste or illusion
  push it further.
- **C. Raise the threshold.** Keep the differences, but let a task count as
  valuable or urgent only above +k (k around 3). The quadrant lines move away
  from the centre of the graph.

Recommendation: use the app for a week with **A** and see whether rating
both sides feels natural. If it does not, choose **B**. Changing the formula
touches `Task.x`/`y`, `CONCEPT.md`, the sample values in
`TaskProvider.loadSampleData` and `test/task_model_test.dart`. Stored data does
not change, because only the four raw scores are stored.

## D4: local login (open)

The email login keeps every account on the device, and the password hash is
sha256 without a salt. It separates people who share one browser or phone,
and does nothing else. The Google and Kakao buttons are placeholders.

- **Keep it** (the current state) until a backend exists, and then swap
  `LocalAuthService` for a real `AuthService`. The tasks are already keyed by
  user id.
- **Drop it** and open straight onto the week view as a single local user.
  This takes one tap fewer to start. Login comes back together with sync.

The decision becomes urgent only when sync (plan phase 4) begins.
