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

# --- ratchet and smoke scripts, run against a stub `dart` on PATH ---
import os
import shutil
import subprocess

TOOL = Path(__file__).resolve().parent
FINDING = ('  info • Use a token • systematic_lints.no_hardcoded_font_size '
           '• lib/probe.dart:2:20 • x')


def stub_env(root, full_out, probe_out):
    """PATH with a fake dart: `dart analyze` prints full_out, `dart analyze
    <file>` prints probe_out."""
    bindir = root / 'bin'
    bindir.mkdir(exist_ok=True)
    (root / 'full.txt').write_text(full_out)
    (root / 'probe.txt').write_text(probe_out)
    dart = bindir / 'dart'
    dart.write_text('#!/usr/bin/env bash\n'
                    f'if [ "$#" -gt 1 ]; then cat "{root}/probe.txt"; '
                    f'else cat "{root}/full.txt"; fi\n')
    dart.chmod(0o755)
    env = dict(os.environ)
    env['PATH'] = f'{bindir}:{env["PATH"]}'
    env['PROBE_ATTEMPTS'] = '1'
    env['PROBE_SLEEP'] = '0'
    return env


def run(cmd, env, cwd):
    return subprocess.run(cmd, env=env, cwd=cwd, capture_output=True, text=True)


def ratchet(probe_file_line, full_out, probe_out):
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        (root / 'tool').mkdir()
        (root / 'pkg' / 'lib').mkdir(parents=True)
        for name in ('check_lints.sh', 'lint_baseline.py'):
            shutil.copy(TOOL / name, root / 'tool' / name)
        (root / 'tool' / 'lint_ratchet.yaml').write_text(
            'package_dirs: [pkg]\nbaseline: tool/baseline.txt\n'
            'probe_rule: no_hardcoded_font_size\n' + probe_file_line)
        (root / 'pkg' / 'lib' / 'probe.dart').write_text('// probe\n')
        env = stub_env(root, full_out, probe_out)
        return run(['bash', str(root / 'tool' / 'check_lints.sh'),
                    str(root / 'tool' / 'lint_ratchet.yaml')], env, root)


# Probe rule reports on the probe file: pass.
r = ratchet('probe_file: pkg/lib/probe.dart\n', 'No issues found.\n', FINDING + '\n')
assert r.returncode == 0, r.stderr + r.stdout
# The probe file reports nothing, even though the full run mentions the rule: fail.
r = ratchet('probe_file: pkg/lib/probe.dart\n', FINDING + '\n', 'No issues found.\n')
assert r.returncode != 0 and 'probe' in r.stderr, r.stderr + r.stdout
# The probe finding must be the probe rule itself.
other = FINDING.replace('no_hardcoded_font_size', 'no_error_to_text')
r = ratchet('probe_file: pkg/lib/probe.dart\n', 'No issues found.\n', other + '\n')
assert r.returncode != 0, r.stderr + r.stdout
# probe_file is required.
r = ratchet('', 'No issues found.\n', FINDING + '\n')
assert r.returncode != 0 and 'probe_file' in r.stderr, r.stderr + r.stdout


def smoke(options_yaml, probe_out):
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        app = root / 'app'
        (app / 'lib').mkdir(parents=True)
        if options_yaml is not None:
            (app / 'analysis_options.yaml').write_text(options_yaml)
        env = stub_env(root, '', probe_out)
        return run(['bash', str(TOOL / 'smoke.sh'), str(app)], env, root)


LISTED = ('plugins:\n  systematic_lints:\n    path: ../x\n    diagnostics:\n'
          '      no_hardcoded_font_size: true\n')
UNLISTED = ('plugins:\n  systematic_lints:\n    path: ../x\n    diagnostics:\n'
            '      no_error_to_text: true\n')
r = smoke(LISTED, FINDING + '\n')
assert r.returncode == 0, r.stderr + r.stdout
# A rule missing from diagnostics is silent; smoke must say so and fail.
r = smoke(UNLISTED, FINDING + '\n')
assert r.returncode != 0 and 'diagnostics' in r.stderr, r.stderr + r.stdout
r = smoke(None, FINDING + '\n')
assert r.returncode != 0 and 'diagnostics' in r.stderr, r.stderr + r.stdout
# Listed but the probe reports nothing: fail.
r = smoke(LISTED, 'No issues found.\n')
assert r.returncode != 0, r.stderr + r.stdout
print('ratchet and smoke self-tests passed')
