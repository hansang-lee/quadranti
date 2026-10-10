# Quadranti Plan

> **Project**: Quadranti, a weekly scheduler that sorts tasks into four quadrants
> **Location**: `/home/hslee/workspace/quadranti` (github.com/hansang-lee/quadranti, **public**)
> **Stack**: Flutter (web + Android), Hive (`hive_ce`) local storage, Provider
> **Plan written**: 2026-10-07

Read `concept.md` (the model) and `decisions.md` (D1, D2, …) first. To run
and check the app, see `development.md`.

Work through the phases in order. Each task is one small commit. Tick the
box in the same commit. A commit cannot contain its own hash, so add the
hash in the next commit that touches this file.
Tasks marked 👤 need the owner (a decision, an account, or a device in hand).

---

## Where the code stands (2026-10-07)

- The local email login works (D4 is open). Each user's tasks are stored in
  their own Hive box and survive reloads. Unreadable records are skipped
  rather than hiding everything.
- Week view: the app bar steps through weeks, and tapping the title jumps to
  this week. A summary line shows the count per quadrant and 완료 n/m. On this
  week, a banner offers to bring over last week's unfinished tasks.
- The graph is responsive, with tinted quadrants, a grid, labelled points and
  faded finished tasks. Tasks rated alike share a dot. Tapping a dot edits the
  task, or asks which one when several share it. Every dot has a screen-reader
  label.
- The list is grouped by quadrant, with done checkboxes, swipe to delete
  (with undo) and tap to edit.
- The editor has a title, a memo and four 0–10 sliders with help text. A live
  card shows the resulting quadrant and x/y.
- Menu: 사용법 (the guide, also shown once per user on arrival), carrying
  unfinished tasks over to the next week, sample tasks, 백업 (a JSON file or
  the clipboard, both ways), and sign-out. Tasks can repeat weekly (D10).
- Dark mode follows the system. IBM Plex Sans KR is bundled. The app icon
  shows the four quadrant colours.
- 77 tests (model, week helpers, provider including race cases, the Hive
  repository, local auth, backup, painter, widget flows). CI runs analyze,
  test and the web build on every push. The debug APK builds locally.
- Seen in a real browser at phone size (light and dark) with
  `tool/web_driver.ts`. Not yet tried on an Android device.

---

## Phase 0: Hygiene ✅

- [x] 0.1 Add the `web/` and `android/` platform folders. The app could not run without them. `532dfd2`
- [x] 0.2 Update to flutter_lints 6 and Dart ^3.9, drop unused deps, clear deprecations. `f6d07c0`
- [x] 0.3 Move to `hive_ce`, and drop the unregistered User adapter (D5). `22b3a50`
- [x] 0.4 Add GitHub Actions CI: analyze, test, build web. `a2bd24e`
- [x] 0.5 Slim down the Docker dev container (no `--privileged`, verified TLS, Flutter 3.47.5). `09d46d3`
- [x] 0.6 Docs: README, PLAN, CONCEPT, DECISIONS, DEVELOPMENT, and `tool/web_driver.ts`. `a28f1b1`

## Phase 1: Bugs ✅

- [x] 1.1 The graph never repainted after a change, because the same list instance was compared by identity. `5aec19c`
- [x] 1.2 Sample tasks were duplicated on every login, and the samples did not cover all four quadrants. `d819ad3`
- [x] 1.3 Email case made duplicate accounts, the password was trimmed, and `setState` ran after dispose. `36cc30f`
- [x] 1.4 Scores were not clamped, so points could be drawn off the canvas. `536cd1b`
- [x] 1.5 Snackbars queued, so undo after two quick deletes acted on the wrong task. `e2e1fc4`
- [x] 1.6 Reviewer findings (2026-10-07). A damaged session left the app stuck on the spinner, and a new account could shadow a legacy mixed-case one. `daa4d3a`
- [x] 1.7 Reviewer findings. Batch writes could land in the next user's box after a switch, one bad record hid every task, and duplicate ids in a backup were kept. `1dd8b88`

## Phase 2: Core MVP ✅

- [x] 2.1 Make `Task` immutable, with week, done, createdAt and toMap/fromMap. `536cd1b`
- [x] 2.2 Persist tasks per user, reloading when the user changes (D3). `ecf146a`
- [x] 2.3 Task editor, week navigation, list grouped by quadrant, delete with undo, empty state. `34310bc`
- [x] 2.4 Responsive, labelled and tappable graph, plus widget flow tests. `9e6a4bb`

## Phase 3: Make it pleasant to use daily

- [ ] 3.1 👤 Settle **D1** (the axis formula), after a week of real use.
- [x] 3.2 Bundle IBM Plex Sans KR (400 and 700) and drop `google_fonts` (D6). `b139ec2`
- [x] 3.10 Tasks with the same scores share one dot: titles stacked beside it ("외 n개" past three), and a tap asks which task to open. `fa9263b`
- [x] 3.3 Guide screen (`GuideScreen`): the four properties, the axes, the quadrants and the week flow. It opens once per user (`Prefs`, Hive box `prefs`) and from 메뉴 → 사용법. Its wording must stay in step with concept.md, so update it with D1. `a5e154f`
- [x] 3.4 Week summary bar above the graph and list: count per quadrant and 완료 n/m. It wraps on narrow screens. `17f8a79`
- [x] 3.5 While viewing this week, a banner offers to bring over last week's unfinished tasks (이번 주로 / 닫기). Closing it hides it until the app restarts. `a4beb2d`
- [ ] 3.6 Drag a point on the graph to re-rate a task, so the four scores scale to match. Needs a rule for splitting a point move between the two properties of each axis. Do this after D1.
- [ ] 3.7 Optional day of the week (월–일) for a task, with a filter in the list. This extends D2, so record the decision first.
- [x] 3.8 Dark mode follows the system (`AppTheme.darkTheme`). `QuadrantPainter` takes `ink`/`surface` from the theme instead of fixed black and white. The login screen stays indigo in both. `94fcbb5`
- [x] 3.9 Each graph dot has a semantics node (titles, quadrant, x/y; `QuadrantPainter.semanticsBuilder`). Activating a task stays with the list view. `13c0978`

## Phase 4: Data safety and accounts

- [x] 4.1 JSON backup through the clipboard (now under 메뉴 → 백업). Import merges by id and never deletes. Format: `TaskBackup` (`lib/services/task_backup.dart`), version 1. `6eb13e0`
- [x] 4.1b Back up to and restore from a `.json` file (메뉴 → 백업 → 파일로 저장 / 파일에서 불러오기) with `file_picker`: a download on web, the system save and open dialogs on Android. `lib/services/backup_files.dart` is the seam that tests replace. Web download was checked in headless Chrome; Android so far only builds. `a1b7240`
- [x] 4.2 Weekly repeating tasks (D10): a 매주 반복 switch in the editor and a 매주 mark in the list. Rules are stored per user and included in backups (version 2). `e86cb9d` `106d09a`, with review fixes in `1a72f26`.
- [ ] 4.3 👤 Settle **D4** (keep or drop the local login).
- [ ] 4.4 👤 Choose a sync backend (e.g. reuse the cling Go/Postgres setup, Supabase or Firebase). This decides the cost and the accounts needed.
  Hosting notes (2026-10-07): the Railway Hobby plan the owner already pays
  for cling ($5/month, which includes $5 of usage, and allows up to 50
  projects per workspace) can hold a separate `quadranti` project. No second
  subscription is needed, but usage is billed on top of the shared $5 credit
  (roughly $10/GB-month of RAM and $20/vCPU-month). Until sync exists the app
  needs no server, and the web build is static, so GitHub Pages would host it
  for free (5.2).
- [ ] 4.5 Google and Kakao sign-in through a real `AuthService` implementation. Needs 4.4 and per-platform OAuth clients (👤).
- [ ] 4.6 Sync local tasks to the backend and migrate existing local data on first sign-in.

## Phase 5: Release

- [x] 5.1 App icon: the four quadrant colours on indigo (`assets/icon/`, generated with `dart run flutter_launcher_icons`), including the Android adaptive icon and the web/PWA icons. The debug APK builds. A splash screen is still the default. `4e4c9f4`
- [x] 5.2 The web build is public at https://hansang-lee.github.io/quadranti/, deployed by the `deploy` job in `ci.yml` after every green push to `master` (built with `--base-href /quadranti/`). Approved by the owner 2026-10-07.
- [ ] 5.3 👤 Android release signing (keystore kept out of git) and a Play Console listing.
- [ ] 5.4 Privacy note: what is stored, and where.
