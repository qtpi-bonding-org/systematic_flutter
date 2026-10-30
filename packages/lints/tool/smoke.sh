#!/usr/bin/env bash
# Proves the plugin is loaded for an app: plants a file with a known violation,
# runs `dart analyze` until the finding shows up, then removes the file.
# The first analyze after setup can report nothing while the plugin builds, so a
# clean `dart analyze` means nothing until this passes.
#
# Needs no_hardcoded_font_size enabled in the app's analysis_options.yaml.
# Usage: tool/smoke.sh <app dir>
set -euo pipefail
app="${1:?usage: smoke.sh <app dir>}"
probe="$app/lib/_systematic_lints_smoke.dart"
trap 'rm -f "$probe"' EXIT
cat > "$probe" <<'DART'
class TextStyle {
  const TextStyle({double? fontSize});
}

final probe = TextStyle(fontSize: 13);
DART
for attempt in 1 2 3; do
  if (cd "$app" && dart analyze lib/_systematic_lints_smoke.dart 2>&1 | grep -q 'no_hardcoded_font_size'); then
    echo "systematic_lints is loaded (attempt $attempt)"
    exit 0
  fi
  sleep 5
done
echo "systematic_lints did not report the planted violation; its findings cannot be trusted" >&2
exit 1
