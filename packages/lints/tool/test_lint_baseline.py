#!/usr/bin/env python3
import importlib.util
import io
import sys
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location('baseline', Path(__file__).with_name('lint_baseline.py'))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

OLD_A = '  info • message • systematic_lints.no_error_to_text • lib/a.dart:3:4 • ...'
OLD_B = '  warning • message • systematic_lints.no_string_error_in_state • lib/a.dart:4:4 • ...'
sample = f'Analyzing lib/a.dart...\n{OLD_A}\n{OLD_B}\n2 issues found.\n'
assert len(mod.findings(sample)) == 2
assert mod.parse_findings(sample) == {
    'lib/a.dart|no_error_to_text': 1, 'lib/a.dart|no_string_error_in_state': 1}

# Dart 3.13 format: no systematic_lints prefix, ' - ' separators, rule id last.
NEW = ('   info - lint_probe.dart:9:25 - There is one text size, and AppSizes '
       'owns it. - no_hardcoded_font_size')
new_sample = 'Analyzing lint_probe.dart...\n\n' + NEW + '\n\n1 issue found.\n'
assert mod.findings(new_sample) == [NEW]
assert mod.findings('Analyzing x...\nNo issues found.\n') == []
assert mod.parse_findings(new_sample) == {'lint_probe.dart|no_hardcoded_font_size': 1}


def f(path, line, rule='no_hardcoded_colors', msg='Use a token'):
    return f'   info - {path}:{line}:5 - {msg} - {rule}\n'


def check(baseline_text, out_text, *extra):
    """Run main() in --baseline mode; returns (code, stdout, stderr, baseline_path text)."""
    with tempfile.TemporaryDirectory() as d:
        base = Path(d) / 'b.txt'
        out = Path(d) / 'out.txt'
        if baseline_text is not None:
            base.write_text(baseline_text)
        out.write_text(out_text)
        o, e = io.StringIO(), io.StringIO()
        so, se = sys.stdout, sys.stderr
        sys.stdout, sys.stderr = o, e
        try:
            code = mod.main(['--baseline', str(base), *extra, str(out)])
        finally:
            sys.stdout, sys.stderr = so, se
        return code, o.getvalue(), e.getvalue(), (base.read_text() if base.exists() else None)


BASE = 'lib/a.dart|no_hardcoded_colors=1\n'
# Missing or empty baseline: a finding fails.
assert check(None, f('lib/a.dart', 3))[0] == 1
assert check('', f('lib/a.dart', 3))[0] == 1
# Moving a baselined finding to another line passes.
assert check(BASE, f('lib/a.dart', 3))[0] == 0
assert check(BASE, f('lib/a.dart', 40, msg='different words'))[0] == 0
# A second finding of the same rule in the same file fails.
code, out, err, _ = check(BASE, f('lib/a.dart', 3) + f('lib/a.dart', 9))
assert code == 1 and 'lib/a.dart' in err + out, err + out
# A finding in a new file fails.
assert check(BASE, f('lib/a.dart', 3) + f('lib/b.dart', 1))[0] == 1
# Same file, new rule fails.
assert check(BASE, f('lib/a.dart', 3) + f('lib/a.dart', 4, rule='no_error_to_text'))[0] == 1
# A removed finding passes and is reported as an improvement.
code, out, err, _ = check(BASE + 'lib/b.dart|no_hardcoded_colors=2\n', f('lib/a.dart', 3) + f('lib/b.dart', 1))
assert code == 0 and 'improvement' in (out + err).lower() and 'lib/b.dart' in out + err, out + err
code, out, err, _ = check(BASE, '')
assert code == 0 and 'improvement' in (out + err).lower(), out + err
# --update rewrites the baseline as file|rule=count, sorted, with counts.
code, _, _, text = check(None, f('lib/b.dart', 1) + f('lib/a.dart', 3) + f('lib/a.dart', 8), '--update')
assert code == 0
assert [l for l in text.splitlines() if not l.startswith('#')] == [
    'lib/a.dart|no_hardcoded_colors=2', 'lib/b.dart|no_hardcoded_colors=1'], text
# Old whole-line baselines are migrated on read: line numbers no longer matter.
old_baseline = OLD_A + '\n' + OLD_A.replace(':3:4', ':9:4') + '\n'
assert check(old_baseline, sample.replace(':3:4', ':30:4').replace(OLD_B, ''))[0] == 0
assert check(old_baseline, sample)[0] == 1  # OLD_B is new; the old baseline never had it
assert mod.read_baseline(old_baseline) == {'lib/a.dart|no_error_to_text': 2}
# --require-any is unchanged.
assert check(None, 'No issues found.\n', '--require-any')[0] == 1
assert check(None, NEW + '\n', '--require-any')[0] == 0
# stdin input is still accepted.
old = sys.stdin
try:
    sys.stdin = io.StringIO(sample)
    with tempfile.TemporaryDirectory() as d:
        assert mod.main(['--baseline', str(Path(d) / 'u.txt'), '--update']) == 0
        assert mod.read_baseline((Path(d) / 'u.txt').read_text()) == mod.parse_findings(sample)
finally:
    sys.stdin = old
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
# The 3.13 line format (no systematic_lints prefix) is what the stub prints.
FINDING_313 = ('   info - lib/probe.dart:2:20 - Use a token - '
               'no_hardcoded_font_size')
r = ratchet('probe_file: pkg/lib/probe.dart\n', FINDING_313 + '\n', FINDING_313 + '\n')
assert r.returncode != 0, 'a new 3.13 finding vs empty baseline must fail: ' + r.stdout
r = ratchet('probe_file: pkg/lib/probe.dart\n', 'No issues found.\n', FINDING_313 + '\n')
assert r.returncode == 0, r.stderr + r.stdout
# The probe reports its rule in a format the parser does not recognise: fail loudly.
r = ratchet('probe_file: pkg/lib/probe.dart\n', 'No issues found.\n',
            'WARN some future format mentions no_hardcoded_font_size here\n')
assert r.returncode != 0 and 'format' in r.stderr, r.stderr + r.stdout
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
DISABLED = ('plugins:\n  systematic_lints:\n    path: ../x\n    diagnostics:\n'
            '      no_hardcoded_font_size: false\n')
r = smoke(LISTED, FINDING + '\n')
assert r.returncode == 0, r.stderr + r.stdout
r = smoke(LISTED, FINDING_313 + '\n')
assert r.returncode == 0, r.stderr + r.stdout
# Rules are on by default: an unlisted rule, or no options file, still passes.
r = smoke(UNLISTED, FINDING + '\n')
assert r.returncode == 0, r.stderr + r.stdout
r = smoke(None, FINDING + '\n')
assert r.returncode == 0, r.stderr + r.stdout
# A probe rule turned off explicitly: smoke must say so and fail.
r = smoke(DISABLED, FINDING + '\n')
assert r.returncode != 0 and 'turned off' in r.stderr, r.stderr + r.stdout
# Listed but the probe reports nothing: fail.
r = smoke(LISTED, 'No issues found.\n')
assert r.returncode != 0, r.stderr + r.stdout
print('ratchet and smoke self-tests passed')
