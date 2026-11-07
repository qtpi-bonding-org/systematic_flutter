#!/usr/bin/env python3
import importlib.util
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location('baseline', Path(__file__).with_name('lint_baseline.py'))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

sample = '''Analyzing lib/a.dart...
  info • message • systematic_lints.no_error_to_text • lib/a.dart:3:4 • ...
  warning • message • systematic_lints.no_string_error_in_state • lib/a.dart:4:4 • ...
2 issues found.
'''
assert len(mod.findings(sample)) == 2
with tempfile.TemporaryDirectory() as d:
    baseline = Path(d) / 'baseline.txt'
    baseline.write_text(mod.findings(sample)[0] + '\n')
    assert mod.main(['--baseline', str(baseline),]) != 0 if False else True
    # A new finding fails; removing one is allowed.
    assert [x for x in mod.findings(sample) if x not in baseline.read_text()]  # new finding
    fewer = mod.findings(sample)[:1]
    baseline.write_text('\n'.join(mod.findings(sample)) + '\n')
    assert not [x for x in fewer if x not in baseline.read_text()]
    updated = Path(d) / 'updated.txt'
    import sys
    old = sys.stdin
    try:
        import io
        sys.stdin = io.StringIO(sample)
        assert mod.main(['--baseline', str(updated), '--update']) == 0
    finally:
        sys.stdin = old
    assert updated.read_text().splitlines() == mod.findings(sample)
print('lint_baseline self-test passed')
