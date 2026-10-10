# Quadranti documentation

This page indexes every document and sets the conventions for writing them.
Start with [plan.md](plan.md): what exists, what is open and what comes next.
Agents read [../CLAUDE.md](../CLAUDE.md) first.

## Index

| File | Kind | What it is |
|---|---|---|
| [plan.md](plan.md) | status | The current state and the open tasks by phase. Kept current. |
| [history.md](history.md) | record | Finished tasks, verbatim and by phase. A task id no longer in plan.md is here. |
| [decisions.md](decisions.md) | decision | The decision table D1, D2, …: every decision, made or open, with its date. |
| [concept.md](concept.md) | reference | The four properties, the axis formula and the quadrants: the model the app is built on. |
| [development.md](development.md) | how-to | The toolchain, running the app, the code layout and conventions, and screenshots of the web build. |

## Conventions

These were adopted 2026-10-10 from cling (its `docs/README.md`), which took
them from kairos. They follow the Google documentation guide: docs live in
the repo, change in the same commit as the code they describe, and are
deleted when stale rather than left to mislead. They also follow the Google
developer style guide for file names, and Diátaxis (one kind of document per
file).

**Names.** Use lowercase words joined by hyphens: `plan.md`,
`development.md`. Dated records are named by their ISO 8601 date
(`reviews/2026-10-07.md`). The only upper-case names are the conventional
root files `README.md`, `CLAUDE.md` and `CHANGELOG.md`.

**Where a document goes.**

| Folder | Holds | Changes |
|---|---|---|
| `docs/` | Plan, decisions, history, and how-tos and references about the system as it is | Edited in place and kept current (history only grows) |
| `docs/reviews/` | One review per file, with its findings and their status (none yet: reviews so far became plan tasks) | The status is updated; findings are not rewritten |

Decisions stay one table in `decisions.md`, not one file each. A row is never
edited to say something else; a new row supersedes it.

**Inside a document.**

- Use one `#` title that matches what the file is, then `##` sections and
  `###` subsections.
- The first paragraph says what the document is for and who reads it.
- Write in English, because agents read these. Answer the owner in Korean.
- Lead with the point. Write dates as `2026-10-10`. Say why, and what went
  wrong before.
- Use tables for items compared on several attributes, and numbered lists
  for steps.
- Refer to a task as "PLAN 4.2" and to a decision as "D10". The ids survive
  renames.

**Changing documents.**

- A code change that alters behaviour described in a doc updates that doc in
  the same commit.
- A task is finished when its plan entry is ticked and moved to
  history.md, and the affected doc says what the code now does.
- Renaming or moving a doc updates every reference in the same commit:
  `git grep` the old name, including code comments, scripts, configs and
  workflows.
