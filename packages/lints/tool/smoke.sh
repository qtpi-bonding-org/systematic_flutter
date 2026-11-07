#!/usr/bin/env bash
# Usage: tool/smoke.sh <app-dir> [rule-name] [probe-file]
set -euo pipefail
app="${1:?usage: smoke.sh <app dir> [rule] [probe file]}"
rule="${2:-no_hardcoded_font_size}"
probe="${3:-$app/lib/_systematic_lints_smoke.dart}"
mkdir -p "$(dirname "$probe")"
trap 'rm -f "$probe"' EXIT
cat > "$probe" <<'DART'
class TextStyle { const TextStyle({double? fontSize}); }
final probe = TextStyle(fontSize: 13);
DART
for attempt in 1 2 3; do
  if (cd "$app" && dart analyze "$probe" 2>&1 | grep -q "$rule"); then
    echo "systematic_lints is loaded (attempt $attempt; probe $rule)"; exit 0
  fi
  sleep 5
done
echo "systematic_lints did not report probe $rule" >&2; exit 1
