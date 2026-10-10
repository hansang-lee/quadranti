# Quadranti

A weekly scheduler that sorts tasks into four quadrants. Each task is rated
on four properties:

- **effectiveness** (효과) and **waste** (낭비), which give its *value*
- **immediacy** (즉시성) and **illusion** (착각), which give its *real urgency*

The task is then placed on a graph:

| | low value | high value |
|---|---|---|
| **really urgent** | 주의 (busy trap) | 집중 (do it now) |
| **not urgent** | 제거 (drop it) | 계획 (schedule it) |

Flutter app for web and Android. Data stays on the device (Hive).
Web version: https://hansang-lee.github.io/quadranti/ (deployed from `master` by CI).

```bash
scripts/web.sh          # http://localhost:8000
scripts/test/check.sh   # analyze + tests
```

## Docs

The index and the conventions for writing docs are in [docs/README.md](docs/README.md).

- [docs/plan.md](docs/plan.md): roadmap and status. Start here.
- [docs/concept.md](docs/concept.md): the four properties, the axis formula, the quadrants
- [docs/decisions.md](docs/decisions.md): decisions D1, D2, … (open ones need the owner)
- [docs/development.md](docs/development.md): toolchain, run, test, code layout, screenshots
