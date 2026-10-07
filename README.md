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
./serve.sh          # http://localhost:8000
flutter test
```

## Docs

- [docs/PLAN.md](docs/PLAN.md): roadmap and status. Start here.
- [docs/CONCEPT.md](docs/CONCEPT.md): the four properties, the axis formula, the quadrants
- [docs/DECISIONS.md](docs/DECISIONS.md): decisions D1, D2, … (open ones need the owner)
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): toolchain, run, test, code layout, screenshots
