"""Run real HTTP permission checks against a disposable PocketBase database."""
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request


def main():
    executable = str(Path(sys.argv[1]).resolve())
    with tempfile.TemporaryDirectory(prefix='employee-auth-test-') as temp:
        root = Path(temp)
        migrations = root / 'pb_migrations'
        migrations.mkdir()
        fields = [dict(name=name, type='text') for name in [
            'first_name', 'last_name', 'national_code_', 'mobile',
            'personnel_code', 'job_title', 'department']]
        fields += [dict(name=name, type='date') for name in ['hire_date', 'end_date']]
        fields += [dict(name='is_active', type='bool')]
        schema = dict(name='employees', type='base', fields=fields)
        (migrations / '1788739199_fixture_schema.js').write_text(
            'migrate((app) => app.save(new Collection(' + json.dumps(schema) + ')));', encoding='utf-8')
        shutil.copy(Path(__file__).resolve().parents[1] / 'pb_migrations' /
                    '1788739200_employee_auth.js', migrations)
        (migrations / '1788739201_fixture_users.js').write_text('''
migrate((app) => {
  for (const role of ['admin', 'user']) {
    const record = new Record(app.findCollectionByNameOrId('users'));
    record.set('email', role + '@example.test');
    record.set('name', role);
    record.set('role', role);
    record.set('password', $os.getenv('EMPLOYEE_TEST_PASSWORD'));
    app.save(record);
  }
});
''', encoding='utf-8')
        password = secrets.token_urlsafe(32)
        environment = dict(os.environ, EMPLOYEE_TEST_PASSWORD=password)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        base = f'http://127.0.0.1:{port}'
        log = (root / 'server.log').open('w', encoding='utf-8')
        process = subprocess.Popen([executable, 'serve', '--http', f'127.0.0.1:{port}',
            '--dir', str(root / 'pb_data'), '--migrationsDir', str(migrations)],
            env=environment, stdout=log, stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)

        def request(method, path, data=None, token=None):
            headers = {'Content-Type': 'application/json'}
            if token:
                headers['Authorization'] = token
            req = urllib.request.Request(base + '/api/' + path,
                data=json.dumps(data).encode() if data is not None else None,
                headers=headers, method=method)
            try:
                with urllib.request.urlopen(req, timeout=5) as response:
                    body = response.read()
                    return response.status, json.loads(body) if body else None
            except urllib.error.HTTPError as error:
                return error.code, json.loads(error.read())

        try:
            for attempt in range(100):
                if process.poll() is not None:
                    log.flush()
                    raise RuntimeError((root / 'server.log').read_text(encoding='utf-8'))
                try:
                    if request('GET', 'health')[0] == 200:
                        break
                except OSError:
                    pass
                time.sleep(0.1)
            else:
                raise RuntimeError('Server did not start')
            accounts = {}
            for role in ['admin', 'user']:
                status, body = request('POST', 'collections/users/auth-with-password',
                    {'identity': role + '@example.test', 'password': password})
                assert status == 200, (role, status)
                assert body['record']['role'] == role
                accounts[role] = body
            admin = accounts['admin']['token']
            user = accounts['user']['token']
            employee = dict(first_name='Test', last_name='Employee', national_code_='0012345678',
                personnel_code='test1', mobile='09123456789', hire_date='2020-01-01 00:00:00.000Z', is_active=True)
            endpoint = 'collections/employees/records'
            status, created = request('POST', endpoint, employee, admin)
            assert status == 200, status
            record_path = endpoint + '/' + created['id']
            assert request('GET', endpoint)[1]['items'] == []
            assert request('GET', record_path)[0] == 404
            assert request('GET', endpoint, token=user)[1]['totalItems'] == 1
            assert request('GET', record_path, token=user)[0] == 200
            assert request('POST', endpoint, employee, user)[0] == 400
            assert request('PATCH', record_path, {'first_name': 'Denied'}, user)[0] == 404
            assert request('DELETE', record_path, token=user)[0] == 404
            assert request('PATCH', 'collections/users/records/' + accounts['user']['record']['id'],
                           {'role': 'admin'}, user)[0] == 403
            assert request('POST', 'collections/users/records', {}, user)[0] == 403
            assert request('POST', 'collections/users/auth-refresh', {}, user)[0] == 200
            assert request('PATCH', record_path, {'first_name': 'Updated'}, admin)[0] == 200
            assert request('DELETE', record_path, token=admin)[0] == 204
            print('PocketBase integration passed: login, refresh, anonymous denial, user read-only, admin CRUD, role escalation blocked.')
        finally:
            process.terminate()
            process.wait(timeout=10)
            log.close()


if __name__ == '__main__':
    main()
