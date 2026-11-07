#!/usr/bin/env bash
# Usage: tool/check_lints.sh [config.yaml]
set -euo pipefail
config="${1:-tool/lint_ratchet.yaml}"
root="$(cd "$(dirname "$config")/.." && pwd)"
# Keep the config intentionally small and dependency-free: scalar values and a
# one-line YAML list are sufficient for a ratchet configuration.
read_config() { sed -n -E "s/^$1:[[:space:]]*//p" "$config" | head -1 | sed -E 's/#.*$//' | tr -d '[]' | tr ',' ' '; }
packages=( $(read_config package_dirs) )
baseline="$(read_config baseline | xargs)"
probe="$(read_config probe_rule | xargs)"
: "${packages:?package_dirs is required}"; : "${baseline:?baseline is required}"; : "${probe:?probe_rule is required}"
output="$(mktemp)"; trap 'rm -f "$output"' EXIT
loaded=0
for package in "${packages[@]}"; do
  (cd "$root/$package" && dart analyze 2>&1) | tee -a "$output"
  grep -q "systematic_lints\.${probe}\|${probe}" "$output" && loaded=1 || true
done
if [[ "$loaded" != 1 ]]; then echo "systematic_lints probe did not appear: $probe" >&2; exit 1; fi
python3 "$root/tool/lint_baseline.py" --baseline "$root/$baseline" "$output"
