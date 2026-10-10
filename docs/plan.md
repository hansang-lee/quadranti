# Quadranti Plan

> **Project**: Quadranti, a weekly scheduler that sorts tasks into four quadrants
> **Location**: `/home/hslee/workspace/quadranti` (github.com/hansang-lee/quadranti, **public**)
> **Stack**: Flutter (web + Android), Hive (`hive_ce`) local storage, Provider
> **Plan written**: 2026-10-07

Read `concept.md` (the model) and `decisions.md` (D1, D2, …) first. To run
and check the app, see `development.md`.

This file holds what is true now and what is still to do. Finished tasks are
in [history.md](history.md), verbatim and by phase. Phases 0 (hygiene),
1 (bugs) and 2 (core MVP) are finished and are there whole.

Work through the phases in order. Each task is one small commit. When a task
is done, tick it and move it to history.md in the same commit. A commit
cannot contain its own hash, so the next commit that touches history.md adds
it. New problems found along the way get a numbered task here, not a silent
fix.
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

## Phase 3: Make it pleasant to use daily

- [ ] 3.1 👤 Settle **D1** (the axis formula), after a week of real use.
- [ ] 3.6 Drag a point on the graph to re-rate a task, so the four scores scale to match. Needs a rule for splitting a point move between the two properties of each axis. Do this after D1.
- [ ] 3.7 Optional day of the week (월–일) for a task, with a filter in the list. This extends D2, so record the decision first.

## Phase 4: Data safety and accounts

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

- [ ] 5.3 👤 Android release signing (keystore kept out of git) and a Play Console listing.
- [ ] 5.4 Privacy note: what is stored, and where.

## Phase 6: Project structure and scenario tests

The layout follows cling and kairos (owner's request, 2026-10-10).

- [ ] 6.2 Add a root `CLAUDE.md`: what this is, a map of the docs, how we work, how to run and check, and what bites.
- [ ] 6.3 Move the scripts to `scripts/` (with `scripts/README.md`), put run results in a gitignored `out/<YYMMDD_hhmmss>/`, and add `scripts/test/check.sh`.
- [ ] 6.4 Scenario tests (`integration_test/`) on the `cling_e2e` emulator through `scripts/test/scenario.sh`, with a screenshot per step, and `docs/testing.md`.
- [ ] 6.5 Run the same scenarios on web (headless Chrome) in CI.
