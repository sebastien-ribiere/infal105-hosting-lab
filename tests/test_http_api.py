"""Tests HTTP autonomes, sans Docker ni PostgreSQL (mode dégradé uniquement)."""
import json
import threading
import unittest
import urllib.error
import urllib.request
from unittest import mock
from http.server import ThreadingHTTPServer

from app.server import Handler


class ApiContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.http = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.base = 'http://127.0.0.1:' + str(cls.http.server_port)
        cls.thread = threading.Thread(target=cls.http.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.http.shutdown()
        cls.thread.join(timeout=4)
        cls.http.server_close()

    def request(self, method, path, obj=None, data=None):
        if obj is not None:
            data = json.dumps(obj).encode('utf-8')
        req = urllib.request.Request(self.base + path, data=data, method=method)
        if data is not None:
            req.add_header('Content-Type', 'application/json')
        try:
            with urllib.request.urlopen(req, timeout=6) as resp:
                return resp.status, json.loads(resp.read())
        except urllib.error.HTTPError as err:
            return err.code, json.loads(err.read())

    def test_health_is_not_readiness(self):
        code, body = self.request('GET', '/healthz')
        self.assertEqual(code, 200)
        self.assertEqual(body['status'], 'alive')

    def test_unknown_endpoint(self):
        code, _ = self.request('GET', '/nope')
        self.assertEqual(code, 404)

    def test_invalid_json(self):
        code, _ = self.request('POST', '/players', data=b'{invalid}')
        self.assertEqual(code, 400)

    def test_bad_name(self):
        code, _ = self.request('POST', '/players', {'name': ' ', 'score': 0})
        self.assertEqual(code, 400)

    def test_bad_score_not_an_integer(self):
        code, _ = self.request('POST', '/players', {'name': 'Ada', 'score': True})
        self.assertEqual(code, 400)

    def test_bad_score_negative(self):
        code, _ = self.request('POST', '/players', {'name': 'Ada', 'score': -1})
        self.assertEqual(code, 400)

    def test_no_db_ready_is_not_success(self):
        # Absence de PostgreSQL : le mode dégradé doit rendre 503, jamais 200.
        with mock.patch('app.server.db_connection', side_effect=OSError('DB intentionally unavailable')):
            code, _ = self.request('GET', '/readyz')
        self.assertEqual(code, 503)


if __name__ == '__main__':
    unittest.main()
