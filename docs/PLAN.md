# Quadranti Plan

> **Project**: Quadranti, a weekly scheduler that sorts tasks into four quadrants
> **Location**: `/home/hslee/workspace/quadranti` (github.com/hansang-lee/quadranti, **public**)
> **Stack**: Flutter (web + Android), Hive (`hive_ce`) local storage, Provider
> **Plan written**: 2026-10-07

Read `CONCEPT.md` (the model) and `DECISIONS.md` (D1, D2, …) first. To run
and check the app, see `DEVELOPMENT.md`.

Work through the phases in order. Each task is one small commit. Tick the
box in the same commit, and add the hash for tasks that are done.
Tasks marked 👤 need the owner (a decision, an account, or a device in hand).

---

## Where the code stands (2026-10-07)

- The local email login works (D4 is open). Each user's tasks are stored in
  their own Hive box and survive reloads.
- Week view: the app bar steps through weeks. Tapping the title jumps to this
  week.
- The graph is responsive, with tinted quadrants, a grid, labelled points and
  faded finished tasks. Tapping a point opens it for editing.
- The list is grouped by quadrant, with done checkboxes, swipe to delete
  (with undo) and tap to edit.
- The editor has a title, a memo and four 0–10 sliders with help text. A live
  card shows the resulting quadrant and x/y.
- Menu actions: carry unfinished tasks over to the next week, add the sample
  tasks, sign out.
- 42 tests (model, week helpers, provider, Hive repository, local auth,
  painter, widget flows). CI runs analyze, test and the web build on every push.

---

## Phase 0: Hygiene ✅

- [x] 0.1 Add the `web/` and `android/` platform folders. The app could not run without them. `532dfd2`
- [x] 0.2 Update to flutter_lints 6 and Dart ^3.9, drop unused deps, clear deprecations. `f6d07c0`
- [x] 0.3 Move to `hive_ce`, and drop the unregistered User adapter (D5). `22b3a50`
- [x] 0.4 Add GitHub Actions CI: analyze, test, build web. `a2bd24e`
- [x] 0.5 Slim down the Docker dev container (no `--privileged`, verified TLS, Flutter 3.47.5). `09d46d3`
- [x] 0.6 Docs: README, PLAN, CONCEPT, DECISIONS, DEVELOPMENT, and `tool/web_driver.ts`.

## Phase 1: Bugs found in the 2026-10-06 review ✅

- [x] 1.1 The graph never repainted after a change, because the same list instance was compared by identity. `5aec19c`
- [x] 1.2 Sample tasks were duplicated on every login, and the samples did not cover all four quadrants. `d819ad3`
- [x] 1.3 Email case made duplicate accounts, the password was trimmed, and `setState` ran after dispose. `36cc30f`
- [x] 1.4 Scores were not clamped, so points could be drawn off the canvas. `536cd1b`

## Phase 2: Core MVP ✅

- [x] 2.1 Make `Task` immutable, with week, done, createdAt and toMap/fromMap. `536cd1b`
- [x] 2.2 Persist tasks per user, reloading when the user changes (D3). `ecf146a`
- [x] 2.3 Task editor, week navigation, list grouped by quadrant, delete with undo, empty state. `34310bc`
- [x] 2.4 Responsive, labelled and tappable graph, plus widget flow tests. `9e6a4bb`

## Phase 3: Make it pleasant to use daily

- [ ] 3.1 👤 Settle **D1** (the axis formula), after a week of real use.
- [ ] 3.2 Bundle the IBM Plex Sans KR font as an asset (D6), so the app works offline and does not flash the fallback font on web.
- [ ] 3.3 Onboarding: one screen that explains the four properties and the quadrants, shown on first sign-in and reachable from the menu.
- [ ] 3.4 Week summary bar: count per quadrant and the done ratio for the selected week, shown above the graph or list.
- [ ] 3.5 At the start of a new week, offer to carry over last week's unfinished tasks, instead of relying only on the menu.
- [ ] 3.6 Drag a point on the graph to re-rate a task, so the four scores scale to match. Needs a rule for splitting a point move between the two properties of each axis. Do this after D1.
- [ ] 3.7 Optional day of the week (월–일) for a task, with a filter in the list. This extends D2, so record the decision first.
- [ ] 3.8 Dark mode. Quadrant colours and the painter's black/white values become theme-aware.
- [ ] 3.9 Accessibility: semantics labels for graph points, since the canvas is invisible to screen readers. The list view is the accessible path.

## Phase 4: Data safety and accounts

- [ ] 4.1 Export and import all tasks as a JSON file (backup and device moves). This is the first guard against losing local data.
- [ ] 4.2 Repeating tasks (weekly), created when a week is first opened.
- [ ] 4.3 👤 Settle **D4** (keep or drop the local login).
- [ ] 4.4 👤 Choose a sync backend (e.g. reuse the cling Go/Postgres setup, Supabase or Firebase). This decides the cost and the accounts needed.
- [ ] 4.5 Google and Kakao sign-in through a real `AuthService` implementation. Needs 4.4 and per-platform OAuth clients (👤).
- [ ] 4.6 Sync local tasks to the backend and migrate existing local data on first sign-in.

## Phase 5: Release

- [ ] 5.1 App icon and splash (the web manifest and Android icons are Flutter defaults).
- [ ] 5.2 👤 Host the web build, e.g. on GitHub Pages from CI. The repo is public, so the build would be public too.
- [ ] 5.3 👤 Android release signing (keystore kept out of git) and a Play Console listing.
- [ ] 5.4 Privacy note: what is stored, and where.
