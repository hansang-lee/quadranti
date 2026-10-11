# Decisions

Every decision about the product and the project, one row each: the
question, the decision, and who decided it when. Agents read this before
changing behaviour a row covers; the owner reads it for what is still open.

*Open* rows wait for the owner. An "agent default" was chosen by an agent
so the work could go on; it stands until the owner says otherwise. A row is
never rewritten to say something else: a new row supersedes it and says so
(D12 supersedes part of D3). New rows go at the end; ids are never reused.
On 2026-10-11 the table moved from `Date | Status | Decision` columns to
these, as `conventions.md` §3 asks. The decision texts were kept word for
word, except D1 and D4, whose placeholder ("See below") now says what
applies until the owner decides.

| ID | Question | Decision | Who, when |
|---|---|---|---|
| D1 | How are the four scores turned into the two axes? | — (see "D1: axis formula" below; current behaviour is option A) | *Open* (raised 2026-10-07; owner to decide after a week of use) |
| D2 | What is a task scheduled in: a week, a day, a time slot? | A task belongs to one **week** (Monday to Sunday, `Task.weekStart`), not to a day or time slot. Unfinished tasks move to the next week only when the user asks (menu → 미완료를 다음 주로). | agent default, 2026-10-07 |
| D3 | Where are tasks stored? | Storage is **local only**: one Hive box per user, `tasks_<userId>`, with tasks stored as plain maps (`Task.toMap`), not generated adapters. There is no sync or backup yet. | agent default, 2026-10-07 (backup note superseded by D12) |
| D4 | Keep the local email login, or open straight onto the app? | — (see "D4: local login" below; the login stays until decided) | *Open* (raised 2026-10-07; owner, urgent only with sync, PLAN 4.4) |
| D5 | Which Hive package? | `hive_ce` instead of `hive`. It is the maintained fork, with the same API and file format. | agent default, 2026-10-07 |
| D6 | Where do the fonts come from? | Fonts are bundled, not fetched: IBM Plex Sans KR Regular and Bold in `assets/fonts` (OFL), declared in `pubspec.yaml`, with `google_fonts` removed. `google_fonts` made one family per weight, so a missing weight failed instead of falling back. Only 400 and 700 ship (about 2.8 MB each); w500 and w600 resolve to the nearest of the two. Canvas text (`QuadrantPainter`) and explicit `TextStyle`s in the theme must set `AppTheme.fontFamily` themselves. | agent default, 2026-10-07 |
| D7 | Which language for the UI, and which for everything else? | The app UI is in Korean. Code, comments, docs and commit messages are in English. | owner's standing rule (docs, code and output in English; UI in Korean), recorded 2026-10-07 |
| D8 | Which platforms? | Platforms are **web and Android**. iOS is added when there is a Mac to build on. | agent default, 2026-10-07 |
| D9 | Are sample tasks added on their own? | Sample tasks are never seeded on their own. An empty week shows a button that adds them. | agent default, 2026-10-07 |
| D10 | How do repeating tasks work? | Repeating tasks are **weekly only**. Each rule (`RepeatRule`, box `repeats_<userId>`) holds a task template and `lastWeek`. When the real calendar week is later than `lastWeek`, it creates one open instance for that week, with the id `<rule id>-<yyyy-MM-dd>`. Missed weeks are not back-filled. Turning repeat on never creates a copy right away: the first new instance comes with the next calendar week after the later of the task's week, the current week and the series' newest week. Only the newest instance (week >= `lastWeek`) updates the template, so ticking or editing an older week does not roll the series back. Deleting an instance leaves the series running, and switching off 매주 반복 deletes the rule but keeps the instances. Carry-over skips a repeating task when its series is already in the target week. Backups are at version 2 and carry the rules; version 1 is still read. | agent default, 2026-10-07; review fixes the same day |
| D11 | What does the 달력 tab show, when tasks have no day? | The 달력 tab shows a month as rows of weeks (Monday to Sunday, the month of a split week's Thursday first), not tasks on days, because tasks belong to a week (D2). Each row lists the week's count per quadrant, 완료 n/m and its first three open titles, and a tap opens that week in the list. If tasks get an optional day (PLAN 3.7), they can be drawn on their day inside the same rows. Repeating tasks show only in weeks that already have their instance (D10 creates them week by week). | owner asked for the tab, 2026-10-11; the layout is an agent default |
| D12 | Is there a backup, and where is that recorded? (D3 said there was none) | Yes, in the app: 메뉴 → 백업 writes or reads a JSON file or the clipboard (`TaskBackup`, version 2 with repeat rules, D10). Data still lives only on the device; there is no sync. Supersedes D3's 'no sync or backup yet'. | agent, 2026-10-07 (PLAN 4.1, 4.1b); recorded 2026-10-11 |
| D13 | May the web build be public? | Yes: every green push to `master` deploys it to https://hansang-lee.github.io/quadranti/ (the repository is public anyway). How it ships and how to undo a bad deploy: `release.md`. | owner, 2026-10-07 |

## D1: axis formula (open)

The formula is now `x = effectiveness - waste` and `y = immediacy - illusion`.
A task with no waste and no illusion can never leave the 집중 quadrant, however
low its effectiveness or immediacy (see `concept.md`, "Known weakness").

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
touches `Task.x`/`y`, `concept.md`, the sample values in
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
