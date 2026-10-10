# Sourced by the scripts in scripts/: the repository root, Flutter on PATH,
# and the helpers they share. Not run on its own.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if ! command -v flutter >/dev/null 2>&1 && [ -x "$HOME/development/flutter/bin/flutter" ]; then
  export PATH="$HOME/development/flutter/bin:$PATH"
fi

require_flutter() {
  command -v flutter >/dev/null || { echo "flutter not found (expected at ~/development/flutter)" >&2; exit 1; }
}

# Prints the comment block under the shebang as the usage text.
usage_of() { sed -n '2,/^[^#]/p' "$1" | sed '$d' | sed 's/^# \{0,1\}//'; }

# out/YYMMDD_hhmmss/: where a run leaves what it produced (logs,
# screenshots, a summary.txt), named by when it started; gitignored.
# Only the newest $QUADRANTI_KEEP_RUNS (30) runs are kept. new_run_dir KIND
# creates out/<stamp>/KIND and prints out/<stamp>. With QUADRANTI_RUN_DIR
# set (scripts/test/all.sh) every script shares that one run folder.
QUADRANTI_KEEP_RUNS="${QUADRANTI_KEEP_RUNS:-30}"
new_run_dir() {
  if [ -n "${QUADRANTI_RUN_DIR:-}" ]; then
    mkdir -p "$QUADRANTI_RUN_DIR/$1"
    echo "$QUADRANTI_RUN_DIR"
    return
  fi
  local dir="$ROOT/out/$(date +%y%m%d_%H%M%S)"
  mkdir -p "$dir/$1"
  # Oldest first; everything but the newest QUADRANTI_KEEP_RUNS goes.
  find "$ROOT/out" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*_[0-9]*' -printf '%f\n' 2>/dev/null |
    sort | head -n "-$QUADRANTI_KEEP_RUNS" | while read -r old; do rm -rf "${ROOT:?}/out/$old"; done
  echo "$dir"
}

# Appends "<name>: <result>" to the run's summary.txt.
summarize() { echo "$2: $3" >> "$1/summary.txt"; }
