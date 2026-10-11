# Releasing

How a change reaches people, and how to undo a bad one. Read it before
pushing anything that changes what users see or what is stored, and when
something live is wrong. There are two channels: the public web app,
deployed on every push, and the Android app, which is only installed by
hand so far. The store release is still to come (PLAN 5.3, 5.5, 5.6).

## Channels

| | Web | Android (now) | Android (store, planned) |
|---|---|---|---|
| Who gets it | Anyone with the address (D13) | The owner's phone over USB | Play Store users |
| How it ships | CI deploys every green push to `master` | `scripts/phone.sh` | A signed App Bundle uploaded to Play (PLAN 5.3) |
| Signed with | — | Flutter's debug key on this machine | The release keystore, kept out of git (PLAN 5.3) |
| Data | The browser's IndexedDB, per browser | On the phone | On the phone |
| Undo | Below | Install an older build | A new release (Play cannot roll back) |

Data never moves between channels or devices by itself: a user carries it
with 메뉴 → 백업 (D12).

## Web

Address: https://hansang-lee.github.io/quadranti/ (GitHub Pages, public by
D13).

**What a push does.** `.github/workflows/ci.yml` runs three jobs on every
push to `master`:

1. `test`: `scripts/test/check.sh` (shellcheck, analyze, unit and widget
   tests), then `flutter build web --release --base-href /quadranti/`.
   The build is uploaded as the `github-pages` artifact.
2. `scenarios`: the six scenario tests in headless Chrome
   (`scripts/test/scenario.sh --web`), with screenshots kept as an artifact.
3. `deploy`: only when both pass, publishes that artifact. It takes about
   8 minutes from the push.

A red check or scenario run means nothing is deployed and the site keeps
the previous version. Because the pre-push hook (`.githooks/pre-push`) runs
`check.sh` first, a push that would fail `test` should not leave this
machine. The hook does not run the scenarios, so CI is where those are
caught.

**What is live.** The newest GitHub deployment names the commit:

```bash
gh api 'repos/hansang-lee/quadranti/deployments?environment=github-pages&per_page=1' --jq '.[0].sha'
```

The app itself does not show the commit (it shows `v0.1`, see "Gaps").

**Before a push that users will notice.** Do these on top of `check.sh`:
run the scenarios on the emulator (`scripts/test/scenario.sh`), look at the
changed screens (`scripts/screens.sh` or `scripts/phone.sh`), and for a
change to stored data, check that an older record and an older backup
still load (the "stored formats only grow" rule in `CLAUDE.md`). A web
deploy cannot migrate data that is already in users' browsers. The new code
has to read what the old code wrote.

### Undoing a bad deploy

Pick the first that applies:

1. **Within a day of the last good deploy: redeploy it.** Each run's
   `github-pages` artifact is kept for one day. Re-running the `deploy` job
   of the last good run publishes that run's build again, in about a minute:

   ```bash
   gh run list -w CI -L 10                    # find the last good run on master
   gh run rerun <run-id> --job <deploy-job-id>  # ids from: gh run view <run-id> --json jobs
   ```

   Then push a fix or a revert anyway. The next push to `master` deploys
   whatever it contains.
2. **Otherwise: revert and push.** `git revert <bad-sha>`, then
   `scripts/test/check.sh` and push. CI deploys the reverted code in about
   8 minutes. Do not force-push or rewrite `master` without the owner's
   word.
3. **Something harmful is live (a leak, a broken page that loses data) and
   1 and 2 are too slow:** take the site down with
   `gh api -X DELETE repos/hansang-lee/quadranti/pages`. Restore it later
   with `gh api -X POST repos/hansang-lee/quadranti/pages -f build_type=workflow`
   and a push. This is outward-facing: tell the owner first, unless every
   minute counts, and in that case tell them right after.

Users' data survives all three, because it lives in their browsers, not on
the site. A deploy that wrote a format the old code cannot read is the
exception, and it is why stored formats only grow.

## Android

**Now.** `scripts/phone.sh` builds the release APK, signed with this
machine's debug key, and installs it with `adb install -r` on the one phone
plugged in over USB, keeping its data. It never targets an emulator.

- **The signing key is this machine's.** An APK built on another machine
  (another debug key) cannot be installed over this one: Android refuses
  the update. Uninstalling first deletes the phone's data, so take a backup
  in the app first (메뉴 → 백업 → 파일로 저장).
- **Going back** is installing an older build: check out the commit and run
  `scripts/phone.sh`. `adb install -r` refuses a lower `versionCode`
  (`pubspec.yaml`, now `1.0.0+1`). Stay on the same number, or add `-d` by
  hand.

**The store release** has not been built. Its order is set by the plan:

1. PLAN 5.3: a release keystore (kept out of git, with a backup), signing
   config, and a Play Console listing. This needs the owner.
2. Before each release, PLAN 5.5: `scripts/test/scenario.sh --matrix`
   (Android 9, 13 and 16) and the real-device checklist on a Samsung phone.
3. PLAN 5.6: upload to internal testing and read Google Play's pre-launch
   report.
4. Promote to production. Play has no rollback: a bad release is fixed by
   the next one with a higher `versionCode`.

This section becomes the release checklist when 5.3 is done.

## Gaps

- The app shows a fixed `v0.1` (`AppConstants.appVersion`), not the build
  or commit, so a bug report cannot say which version it came from.
  PLAN 5.7.
- There is no `CHANGELOG.md` until the first store release
  (`README.md`, exceptions).
