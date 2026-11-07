#!/usr/bin/env python3
"""Compare dart analyze output with a checked-in lint baseline."""
import argparse, re, sys
from pathlib import Path

# Deliberately matches the plugin's namespace and any rule id, not a rule list.
FINDING_RE = re.compile(r"^\s*(?:error|warning|info)\s*[•:-].*\bsystematic_lints\.[a-z][a-z0-9_]*\b", re.I)

def findings(text):
    return [line.rstrip() for line in text.splitlines() if FINDING_RE.search(line)]

def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--baseline', required=True)
    ap.add_argument('--update', action='store_true')
    ap.add_argument('input', nargs='?', help='analyzer output (default: stdin)')
    args = ap.parse_args(argv)
    text = Path(args.input).read_text() if args.input else sys.stdin.read()
    actual = findings(text)
    path = Path(args.baseline)
    if args.update:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('\n'.join(actual) + ('\n' if actual else ''))
        return 0
    expected = [line.rstrip() for line in path.read_text().splitlines()] if path.exists() else []
    added = [x for x in actual if x not in expected]
    if added:
        print('New systematic_lints findings:', file=sys.stderr)
        print('\n'.join(added), file=sys.stderr)
        return 1
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
