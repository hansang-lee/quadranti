# scripts

Every script for working on Quadranti locally: running the app, the dev
container, checks, scenario tests and screenshots. What each test layer
covers is in [docs/testing.md](../docs/testing.md). Run them from the repository root
(`scripts/<name>`); each prints its usage with `--help`. Script output is in
English.

## Everyday

| Script | What it does | Usage |
|---|---|---|
| `web.sh` | The app in a browser at http://localhost:8000 (Flutter web dev server; `R` hot-restarts). Uses the local Flutter, or the dev container without one. | `scripts/web.sh` · `PORT=8001 scripts/web.sh` |
| `phone.sh` | Builds the release APK (debug-signed until PLAN 5.3) and installs it on the one phone plugged in over USB, keeping its data, then starts it. Never targets an emulator. Once installed the app needs no computer: all data is on the phone. | `scripts/phone.sh` · `--no-build` |
| `docker.sh` | A shell (or one command) in the optional dev container (`Dockerfile`: Flutter 3.47.5 + Android SDK). | `scripts/docker.sh` · `scripts/docker.sh flutter test` |
| `screens.sh` | Screenshots of the real web build in headless Chrome at 412x860: build, serve on :8765, run the steps of `web_driver.ts`, PNGs into `out/<run>/screens/`. A fresh browser profile each run unless `--profile DIR`. Needs Chrome and bun. | `scripts/screens.sh goto:http://localhost:8765/ wait:3000 shot:login` · `--no-build` · `--profile DIR` |
| `web_driver.ts` | The DevTools-protocol driver `screens.sh` runs (steps: goto, click, drag, type, key, wait, shot, scheme, downloads). Run by hand only against a Chrome already on :9333. | `SHOTS=<dir> bun scripts/web_driver.ts <steps>` |

## Tests (`scripts/test/`)

| Script | What it does | Usage |
|---|---|---|
| `test/check.sh` | What CI runs before deploying: `flutter analyze` and the unit + widget tests, logs in `out/<run>/app/`. Ends with "All checks passed." or prints the failing log. | `scripts/test/check.sh` · `--build` (also the release web build) |
| `test/scenario.sh` | The scenario tests (`integration_test/`) through `flutter drive`: on the `cling_e2e` emulator (booted headless if none runs; never a phone), or with `--web` in headless Chrome (chromedriver from `CHROMEDRIVER`, PATH, or fetched once into `~/.cache/quadranti-chromedriver/`). Logs and a screenshot per step in `out/<run>/scenarios/`. CI runs `--web`. `--matrix` runs the same on each Android version in `MATRIX_AVDS` (cling's `cling_api28/33/36`), one emulator at a time, into `scenarios/<avd>/`; it stops running emulators first (after checking every matrix AVD exists) and restores `cling_e2e`. | `scripts/test/scenario.sh` · `scripts/test/scenario.sh repeat backup` · `--web` · `--web --show` · `--matrix` |

## Results (`out/`)

Every run of `check.sh`, `scenario.sh` or `screens.sh` leaves what it produced in
`out/<YYMMDD_hhmmss>/` (the time it started; gitignored):

```
out/261010_143015/
  summary.txt   what ran and PASS/FAIL per part, then the result
  app/          check.sh: pub-get.log, analyze.log, test.log (build.log with --build)
  scenarios/    scenario.sh: logs/<name>.log, screenshots/<name>_<nn>_<step>.png, chromedriver.log (--web)
  screens/      screens.sh: the PNGs, build.log, chrome.log, http.log
```

Only the newest 30 runs are kept (`QUADRANTI_KEEP_RUNS`); the next run
removes older ones. A new kind of run gets its own folder under the run
through `new_run_dir` in `lib/common.sh`.

## Shared code

`lib/common.sh` is sourced by every script: `ROOT`, Flutter on PATH
(`~/development/flutter`), `usage_of` (prints the comment under the
shebang), `new_run_dir` and `summarize`.
