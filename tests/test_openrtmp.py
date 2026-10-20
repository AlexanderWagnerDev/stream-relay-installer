"""Exercise installer prompts and nginx migration without touching the host."""
import itertools
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'install.sh'
TOKEN = 'a' * 64
MOCK = r'''#!/usr/bin/env python3
import json, os, sys
a = sys.argv[1:]
with open(os.environ['CALLS'], 'a') as f:
    f.write(json.dumps(a) + '\n')
if a[0] == 'logs' and a[1] == 'srtla-server':
    print('Generated default admin API key: ' + 'c' * 64)
elif a[0] == 'logs':
    print('Generated API token (stored in database /data/server.db):\n' + 'a' * 64)
elif a[0] == 'inspect':
    fmt = a[-1]
    if 'PortBindings' in fmt: print('8090:80/tcp 1935:1935/tcp')
    elif 'RestartPolicy' in fmt: print('unless-stopped')
    elif 'State.Running' in fmt: print('true')
    elif 'Health.Status' in fmt: print('healthy')
elif a[0] == 'ps':
    print('rtmp-server\nrtmppanel')
'''


class OpenRTMPTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        bindir = self.root / 'bin'
        bindir.mkdir()
        for name, code in {'docker': MOCK, 'sleep': '#!/bin/sh\nexit 0\n',
                           'sudo': '#!/bin/sh\nexit 0\n', 'curl': '#!/bin/sh\necho 192.0.2.10\n'}.items():
            p = bindir / name
            p.write_text(code)
            p.chmod(0o755)
        self.env = dict(os.environ, PATH=str(bindir) + ':' + os.environ['PATH'],
                        CALLS=str(self.root / 'calls'))

    def run_script(self, answers, script=None):
        result = subprocess.run(['bash', str(script or SCRIPT)],
                                input='\n'.join(answers) + '\n', text=True,
                                cwd=self.root, env=self.env, capture_output=True,
                                timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        return [json.loads(s) for s in (self.root / 'calls').read_text().splitlines()]

    def test_install_variants(self):
        for lang, login, labels, custom in itertools.product(['1', '2'], [False, True], [False, True], [False, True]):
            with self.subTest(lang=lang, login=login, labels=labels, custom=custom):
                answers = [lang, '1', 'n', 'n', 'n', 'n' if custom else 'y']
                if custom:
                    answers += ['4100', '4101', '5100', '8889', '8190', '2935', '8100', '8101']
                answers += ['n', 'y' if labels else 'n']
                if labels:
                    answers += ['y']
                answers += ['y', 'n', 'n', 'y', 'y' if login else 'n']
                if login:
                    answers += ['admin', 'test-password']
                calls = self.run_script(answers)
                server = next(a for a in reversed(calls) if a[:4] == ['run', '-d', '--name', 'rtmp-server'])
                panel = next(a for a in reversed(calls) if a[:4] == ['run', '-d', '--name', 'rtmppanel'])
                self.assertIn('8190:8080/tcp' if custom else '8090:8080/tcp', server)
                self.assertIn('rtmp-server-data:/data', server)
                self.assertIn('rtmppanel-data:/data', panel)
                self.assertIn('8101:8000/tcp' if custom else '8001:8000/tcp', panel)
                self.assertIn('LRTMP2_API_TOKEN=' + TOKEN, panel)
                self.assertIn('REQUIRE_LOGIN=' + str(login), panel)
                self.assertEqual(panel[-1], 'alexanderwagnerdev/rtmppanel:beta')
                self.assertEqual((self.root / '.rtmp_api_token').stat().st_mode & 0o777, 0o600)
                secret = (self.root / '.rtmppanel_secret').read_text().strip()
                self.assertEqual(len(secret), 64)
                self.assertIn('SECRET_KEY=' + secret, panel)

    def test_legacy_update_preserves_host_port_and_adds_database(self):
        functions = SCRIPT.read_text().split('echo "Wähle Sprache / Choose language:"')[0]
        script = self.root / 'update.sh'
        script.write_text(functions + '\nlang=en\nrecreate_container rtmp-server alexanderwagnerdev/rtmp-server:beta ghcr.io/alexanderwagnerdev/rtmp-server:beta\n')
        calls = self.run_script([], script)
        run = next(a for a in calls if a[:2] == ['run', '-d'])
        self.assertIn('8090:8080/tcp', run)
        self.assertNotIn('8090:80/tcp', run)
        self.assertIn('rtmp-server-data:/data', run)
        self.assertLess(next(i for i, a in enumerate(calls) if a[0] == 'pull'),
                        next(i for i, a in enumerate(calls) if a[0] == 'stop'))

    def test_sls_panel_uses_documented_login_variables(self):
        calls = self.run_script(['2', '1', 'n', 'n', 'n', 'y', 'n', 'n',
                                 'n', 'y', 'y', 'y', 'admin', 'test-password', 'n'])
        panel = next(a for a in calls if a[:4] == ['run', '-d', '--name', 'slspanel'])
        self.assertIn('USERNAME=admin', panel)
        self.assertIn('PASSWORD=test-password', panel)
        self.assertIn('SLS_API_KEY=' + 'c' * 64, panel)
        self.assertFalse(any(a.startswith('WEB_USERNAME=') or a.startswith('WEB_PASSWORD=') for a in panel))

    def test_uninstall_keeps_credentials_with_volumes(self):
        for name in ['.rtmp_api_token', '.rtmppanel_secret']:
            (self.root / name).write_text(TOKEN)
        self.run_script(['2', '5', 'n'])
        for name in ['.rtmp_api_token', '.rtmppanel_secret']:
            self.assertEqual((self.root / name).read_text(), TOKEN)
        self.run_script(['2', '5', 'y'])
        for name in ['.rtmp_api_token', '.rtmppanel_secret']:
            self.assertFalse((self.root / name).exists())


if __name__ == '__main__':
    unittest.main()
