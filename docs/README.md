# Quadranti documentation

This page indexes every document and lists this project's exceptions to the
shared conventions. Start with [plan.md](plan.md): what exists, what is open
and what comes next. Agents read [../CLAUDE.md](../CLAUDE.md) first.

## Index

| File | Kind | What it is |
|---|---|---|
| [conventions.md](conventions.md) | reference | This repository's copy of the owner's shared conventions, synced from the template (`~/.claude/project-conventions.md`); exceptions are below. |
| [plan.md](plan.md) | status | The current state and the open tasks by phase. Kept current. |
| [history.md](history.md) | record | Finished tasks, verbatim and by phase. A task id no longer in plan.md is here. |
| [decisions.md](decisions.md) | decision | The decision table D1, D2, …: the question, the decision, and who decided it when (open ones wait for the owner). |
| [concept.md](concept.md) | reference | The four properties, the axis formula and the quadrants: the model the app is built on. |
| [release.md](release.md) | how-to | How the web app and the Android app ship, what is live, and how to undo a bad deploy. |
| [testing.md](testing.md) | how-to | The test layers (unit/widget, scenario), how to run each, what each scenario covers, the backlog. |
| [development.md](development.md) | how-to | The toolchain, running the app, the code layout and conventions, and screenshots of the web build. |

## Conventions

Naming, where a document goes, how it is written and when it changes follow
the owner's shared conventions in [`conventions.md`](conventions.md) (adopted
2026-10-11; sections 1 and 3 for documents, 4 for scripts). Read that file
before changing the layout, docs, scripts or tooling. Quadranti's own
exceptions, with the reason:

| Exception | Why |
|---|---|
| No `.env.example` | There are no secrets: the app has no server, no API keys and no accounts outside the device. The Android release keystore (PLAN 5.3) will stay out of git. If a secret ever appears, add `.env.example` then. |
| No `scripts/export-local.sh` / `import-local.sh` | There is no local state outside git. User data lives in the browser's IndexedDB or on the phone and has its own in-app backup (`TaskBackup`, D3). Development needs no secrets. Revisit with the release keystore (PLAN 5.3). |
| No `CHANGELOG.md` | Nothing is shipped to users as a versioned artifact yet; the web app is deployed continuously. Add one with the first store release. |
| No `docs/reviews/` | No review has been written as a file; reviews so far became plan tasks. |
| `scripts/web_driver.ts` | A TypeScript helper for `screens.sh`. Source files follow their language's naming (section 1); `snake_case` matches the Dart files. |
| `check.sh` and `scenario.sh` use `set -uo pipefail` | They must run every step to report every result (section 4). Each says so in a comment. |
| shellcheck fails on warnings only | Style-level notes (such as quoting inside `${x#$y}`) are not enforced. |
| Older commits use `type: subject` | The `type(scope):` form (section 7) applies from 2026-10-11; history is not rewritten. |
