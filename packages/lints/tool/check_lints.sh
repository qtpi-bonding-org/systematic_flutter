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
probe_file="$(read_config probe_file | xargs)"
: "${packages:?package_dirs is required}"; : "${baseline:?baseline is required}"; : "${probe:?probe_rule is required}"
: "${probe_file:?probe_file is required: a repo-root-relative file that deliberately violates probe_rule}"
if [[ ! -f "$root/$probe_file" ]]; then echo "probe_file does not exist: $probe_file" >&2; exit 1; fi

# True when analyzer output $1 has a systematic_lints line naming rule $2 as a whole word.
reports_rule() { printf '%s\n' "$1" | grep systematic_lints | grep -w -- "$2" >/dev/null; }

output="$(mktemp)"; probe_out="$(mktemp)"; trap 'rm -f "$output" "$probe_out"' EXIT
for package in "${packages[@]}"; do
  (cd "$root/$package" && dart analyze 2>&1) | tee -a "$output"
done

# The probe runs in the package that contains probe_file (longest matching prefix wins).
probe_pkg=""
for package in "${packages[@]}"; do
  p="${package%/}"
  if [[ "$probe_file" == "$p/"* && ${#p} -gt ${#probe_pkg} ]]; then probe_pkg="$p"; fi
done
if [[ -z "$probe_pkg" ]]; then echo "probe_file $probe_file is not under any package_dirs entry" >&2; exit 1; fi
probe_rel="${probe_file#"$probe_pkg"/}"

attempts="${PROBE_ATTEMPTS:-3}"; sleep_s="${PROBE_SLEEP:-5}"
hit=0
for (( attempt = 1; attempt <= attempts; attempt++ )); do
  # The analyzer exits non-zero when it reports the probe, so ignore its status and read the output.
  (cd "$root/$probe_pkg" && dart analyze "$probe_rel" 2>&1) > "$probe_out" || true
  if reports_rule "$(cat "$probe_out")" "$probe"; then hit=1; break; fi
  if (( attempt < attempts )); then sleep "$sleep_s"; fi
done
if [[ "$hit" != 1 ]]; then
  echo "probe did not fire: systematic_lints rule $probe reported nothing for $probe_file after $attempts attempt(s) (is $probe listed under plugins: systematic_lints: diagnostics:?)" >&2
  exit 1
fi

python3 "$root/tool/lint_baseline.py" --baseline "$root/$baseline" "$output"
