#!/usr/bin/env bash
# Runs the shared lint ratchet and probe check for this app.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
exec bash "$here/../../../packages/lints/tool/check_lints.sh" "$here/lint_ratchet.yaml"
