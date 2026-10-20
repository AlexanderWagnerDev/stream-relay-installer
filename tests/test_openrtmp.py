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
if a[:2] == ['network', 'connect'] and os.environ.get('FAIL_NETWORK_CONNECT'):
    sys.exit(1)
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
    elif 'NetworkSettings.Networks' in fmt: print(os.environ.get('MOCK_NETWORKS', 'bridge'))
    elif 'Config.Env' in fmt: print(os.environ.get('MOCK_CONTAINER_ENV', ''))
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
        self.last_result = result
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
                self.assertIn('LRTMP2_API_URL=http://rtmp-server:8080', panel)
                self.assertIn('LRTMP2_STATS_URL=http://192.0.2.10:' + ('8190' if custom else '8090'), panel)
                self.assertEqual(panel[panel.index('--network') + 1], 'openrtmp')
                self.assertEqual(server[server.index('--network') + 1], 'openrtmp')
                self.assertIn('GUNICORN_WORKERS=1', panel)
                self.assertIn('ALLOW_INSECURE_NO_LOGIN=' + ('0' if login else '1'), panel)
                self.assertIn('REQUIRE_LOGIN=' + str(login), panel)
                self.assertEqual(panel[-1], 'alexanderwagnerdev/rtmppanel:latest')
                self.assertEqual((self.root / '.rtmp_api_token').stat().st_mode & 0o777, 0o600)
                secret = (self.root / '.rtmppanel_secret').read_text().strip()
                self.assertEqual(len(secret), 64)
                self.assertIn('SECRET_KEY=' + secret, panel)

    def test_legacy_update_preserves_host_port_and_adds_database(self):
        functions = SCRIPT.read_text().split('echo "Wähle Sprache / Choose language:"')[0]
        script = self.root / 'update.sh'
        script.write_text(functions + '\nlang=en\nrecreate_container rtmp-server alexanderwagnerdev/rtmp-server:latest ghcr.io/alexanderwagnerdev/rtmp-server:latest\n')
        calls = self.run_script([], script)
        run = next(a for a in calls if a[:2] == ['run', '-d'])
        self.assertIn('8090:8080/tcp', run)
        self.assertNotIn('8090:80/tcp', run)
        self.assertIn('rtmp-server-data:/data', run)
        self.assertEqual(run[run.index('--network') + 1], 'openrtmp')
        self.assertIn(['network', 'connect', 'bridge', 'rtmp-server'], calls)
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
        self.assertNotIn('RTMPPanel UI:', self.last_result.stdout)

    def helper_script(self, body):
        functions = SCRIPT.read_text().split('echo "Wähle Sprache / Choose language:"')[0]
        script = self.root / 'helper.sh'
        script.write_text(functions + '\nlang=en\n' + body + '\n')
        return script

    def test_update_preserves_extra_networks_and_migrates_panel_api(self):
        self.env['MOCK_NETWORKS'] = 'bridge\nmetrics'
        self.env['MOCK_CONTAINER_ENV'] = 'LRTMP2_API_URL=http://192.0.2.10:8190\nREQUIRE_LOGIN=False'
        calls = self.run_script([], self.helper_script('recreate_container rtmppanel image fallback'))
        run = next(a for a in calls if a[:2] == ['run', '-d'])
        self.assertEqual(run[run.index('--network') + 1], 'openrtmp')
        self.assertIn('LRTMP2_API_URL=http://rtmp-server:8080', run)
        self.assertIn('LRTMP2_STATS_URL=http://192.0.2.10:8190', run)
        self.assertIn('ALLOW_INSECURE_NO_LOGIN=1', run)
        self.assertIn(['network', 'connect', 'bridge', 'rtmppanel'], calls)
        self.assertIn(['network', 'connect', 'metrics', 'rtmppanel'], calls)

    def test_network_attachment_failure_aborts_installation(self):
        self.env['FAIL_NETWORK_CONNECT'] = '1'
        script = self.helper_script('connect_rtmp_backend')
        result = subprocess.run(['bash', str(script)], cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)

    def test_host_network_update_stops_before_container_removal(self):
        self.env['MOCK_NETWORKS'] = 'host'
        script = self.helper_script('recreate_container rtmp-server image fallback')
        result = subprocess.run(['bash', str(script)], cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        calls = [json.loads(s) for s in (self.root / 'calls').read_text().splitlines()]
        self.assertFalse(any(a[0] in ['stop', 'rm'] for a in calls))

    def test_update_does_not_reextract_existing_token(self):
        (self.root / '.rtmp_api_token').write_text(TOKEN)
        calls = self.run_script(['2', '4'])
        self.assertFalse(any(a[0] == 'logs' for a in calls))
        self.assertEqual((self.root / '.rtmp_api_token').read_text(), TOKEN)

    def test_update_recovers_missing_token_once(self):
        calls = self.run_script(['2', '4'])
        self.assertEqual(sum(a[:2] == ['logs', 'rtmp-server'] for a in calls), 1)
        self.assertEqual((self.root / '.rtmp_api_token').read_text().strip(), TOKEN)
        self.assertEqual((self.root / '.rtmp_api_token').stat().st_mode & 0o777, 0o600)

    def test_empty_secret_is_replaced_and_stays_private(self):
        secret = self.root / '.rtmppanel_secret'
        secret.touch(mode=0o644)
        script = self.helper_script('umask 022\nget_or_create_rtmppanel_secret')
        first = subprocess.run(['bash', str(script)], cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(len(secret.read_text().strip()), 64)
        self.assertEqual(secret.stat().st_mode & 0o777, 0o600)
        saved = secret.read_text()
        second = subprocess.run(['bash', str(script)], cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(secret.read_text(), saved)

    def test_secret_generation_fails_without_random_output(self):
        for name in ['openssl', 'python3', 'od']:
            p = self.root / 'bin' / name
            p.write_text('#!/bin/sh\nexit 0\n')
            p.chmod(0o755)
        script = self.helper_script('get_or_create_rtmppanel_secret')
        result = subprocess.run(['bash', str(script)], cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Could not generate', result.stderr)
        self.assertFalse((self.root / '.rtmppanel_secret').exists())

    def test_existing_private_value_permissions_are_restricted(self):
        token = self.root / '.rtmp_api_token'
        token.write_text('old')
        token.chmod(0o644)
        script = self.helper_script('write_private_value .rtmp_api_token new')
        result = subprocess.run(['bash', str(script)], cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(token.read_text().strip(), 'new')
        self.assertEqual(token.stat().st_mode & 0o777, 0o600)

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
