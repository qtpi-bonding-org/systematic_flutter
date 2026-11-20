#!/usr/bin/env bash
# Usage: tool/smoke.sh <app-dir> [rule-name] [probe-file]
# Env: PROBE_ATTEMPTS (default 3), PROBE_SLEEP seconds between attempts (default 5).
set -euo pipefail
app="${1:?usage: smoke.sh <app dir> [rule] [probe file]}"
rule="${2:-no_hardcoded_font_size}"
probe="${3:-$app/lib/_systematic_lints_smoke.dart}"
attempts="${PROBE_ATTEMPTS:-3}"; sleep_s="${PROBE_SLEEP:-5}"

# Rules run unless turned off, so fail only if the probe rule is explicitly disabled.
options="$app/analysis_options.yaml"
if [[ -f "$options" ]] && grep -qE "^[[:space:]]+${rule}:[[:space:]]*false[[:space:]]*(#.*)?$" "$options"; then
  echo "rule $rule is turned off in $options; pick another probe rule or remove '$rule: false'" >&2
  exit 1
fi

# True when analyzer output $1 has a finding line naming rule $2 as a whole word.
# (Dart 3.13 prints no systematic_lints prefix, so the plugin cannot be filtered on.)
reports_rule() { printf '%s\n' "$1" | grep -E '^[[:space:]]*(error|warning|info)' | grep -w -- "$2" >/dev/null; }

mkdir -p "$(dirname "$probe")"
trap 'rm -f "$probe"' EXIT
cat > "$probe" <<'DART'
class TextStyle { const TextStyle({double? fontSize}); }
final probe = TextStyle(fontSize: 13);
DART
for (( attempt = 1; attempt <= attempts; attempt++ )); do
  # The analyzer exits non-zero when it reports the probe, so ignore its status and read the output.
  out="$(cd "$app" && dart analyze "$probe" 2>&1 || true)"
  if reports_rule "$out" "$rule"; then
    echo "systematic_lints is loaded (attempt $attempt; probe $rule)"; exit 0
  fi
  if (( attempt < attempts )); then sleep "$sleep_s"; fi
done
echo "systematic_lints did not report probe $rule" >&2; exit 1
