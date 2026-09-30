"""Smoke-test the documented card-scoped fingerprint."""
from pathlib import Path
import subprocess
import tempfile

common = Path(__file__).resolve().parent / 'skills/zok-plan/zok-common.md'
command = common.read_text().split('```sh\n', 1)[1].split('```', 1)[0]
command = command.replace("'src/card-file' 'tests/card-test'", "'card' 'new file'")

with tempfile.TemporaryDirectory() as root:
    def run(*args):
        return subprocess.check_output(args, cwd=root, stderr=subprocess.PIPE)

    def fingerprint():
        return run('bash', '-c', command)

    run('git', 'init', '-q')
    Path(root, 'card').write_text('before')
    run('git', 'add', 'card')
    run('git', '-c', 'user.name=Test', '-c', 'user.email=test@example.com',
        '-c', 'commit.gpgsign=false', 'commit', '-qm', 'initial')
    before = fingerprint()
    Path(root, 'unrelated').write_text('ignore me')
    assert fingerprint() == before
    Path(root, 'card').write_text('after')
    changed = fingerprint()
    assert changed != before
    Path(root, 'new file').write_text('new')
    assert fingerprint() != changed

print('PASS: card changes invalidate validation; unrelated changes do not')
