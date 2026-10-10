# Quadranti Plan

> **Project**: Quadranti, a weekly scheduler that sorts tasks into four quadrants
> **Location**: `/home/hslee/workspace/quadranti` (github.com/hansang-lee/quadranti, **public**)
> **Stack**: Flutter (web + Android), Hive (`hive_ce`) local storage, Provider
> **Plan written**: 2026-10-07

Read `concept.md` (the model) and `decisions.md` (D1, D2, …) first. To run
and check the app, see `development.md`.

This file holds what is true now and what is still to do. Finished tasks are
in [history.md](history.md), verbatim and by phase. Phases 0 (hygiene),
1 (bugs), 2 (core MVP) and 6 (project structure and scenario tests) are
finished and are there whole.

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
- 79 unit and widget tests, and 6 scenario tests that run on the Android
  emulator and in Chrome (docs/testing.md). CI runs the checks and the web
  scenarios on every push and deploys only when both pass. The debug APK
  builds locally.
- Seen on the 360 dp emulator (scenario screenshots) and in a browser at
  phone size, light and dark (`scripts/screens.sh`). The owner has the web
  build on their phone.

---

## Phase 3: Make it pleasant to use daily

- [ ] 3.1 👤 Settle **D1** (the axis formula), after a week of real use.
- [ ] 3.6 Drag a point on the graph to re-rate a task, so the four scores scale to match. Needs a rule for splitting a point move between the two properties of each axis. Do this after D1.
- [ ] 3.12 Korean text breaks between any two syllables ("다/음 분기"), seen in the screen-fit check at 200 % text. cling wraps between words with `ProseText` / keepAll (word joiners for drawing only); bring the same to task titles, the guide and the dialogs.
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
- [ ] 5.5 Before each release, run `scripts/test/scenario.sh --matrix` (Android 9, 13 and 16) and go through the real-device checklist on a Samsung phone: the file save and open dialogs, the back gesture, the 3-button and gesture navigation bars, the keyboard over the editor and the paste dialog, a 200 % font, and dark mode. Same plan as cling (its 5.41).
- [ ] 5.6 👤 Read Google Play's pre-launch report: an internal-testing upload runs the app on real devices, Samsung included, and reports crashes, layout and accessibility issues with screenshots. Free, and it needs 5.3 first.
