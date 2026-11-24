"""GuildOps Hosting Lab: an independent teaching API, NOT the offline Godot game."""
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MAX_BODY = 4096


def db_connection():
    import psycopg
    password = os.getenv('DB_PASSWORD', '')
    path = os.getenv('DB_PASSWORD_FILE')
    if path:
        with open(path, encoding='utf-8') as fh:
            password = fh.read().strip()
    return psycopg.connect(
        host=os.getenv('DB_HOST', 'postgres'),
        port=int(os.getenv('DB_PORT', '5432')),
        dbname=os.getenv('DB_NAME', 'guildops'),
        user=os.getenv('DB_USER', 'guildops'),
        password=password,
        connect_timeout=3,
    )


def initialize(cur):
    cur.execute('''CREATE TABLE IF NOT EXISTS players (
        id BIGSERIAL PRIMARY KEY,
        name VARCHAR(64) NOT NULL,
        score INTEGER NOT NULL DEFAULT 0
    )''')


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(json.dumps({'event': 'http', 'remote': self.address_string(), 'line': fmt % args}), flush=True)

    def reply(self, status, obj):
        raw = json.dumps(obj, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Content-Length', str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        path = self.path.split('?', 1)[0]
        if path == '/healthz':
            return self.reply(200, {'status': 'alive', 'release': os.getenv('LAB_RELEASE', 'v1')})
        if path in ('/readyz', '/players'):
            try:
                with db_connection() as conn:
                    with conn.cursor() as cur:
                        initialize(cur)
                        if path == '/readyz':
                            cur.execute('SELECT 1')
                            return self.reply(200, {'status': 'ready', 'db': True})
                        cur.execute('SELECT id, name, score FROM players ORDER BY id DESC LIMIT 30')
                        result = [{'id': a, 'name': b, 'score': c} for a,b,c in cur.fetchall()]
                        return self.reply(200, {'players': result})
            except Exception as ex:
                print(json.dumps({'event': 'db_error', 'error': type(ex).__name__}), flush=True)
                return self.reply(503, {'error': 'database unavailable'})
        return self.reply(404, {'error': 'not found'})

    def do_POST(self):
        if self.path != '/players':
            return self.reply(404, {'error': 'not found'})
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if length < 1 or length > MAX_BODY:
                return self.reply(413, {'error': 'invalid body length'})
            data = json.loads(self.rfile.read(length))
            name, score = data.get('name'), data.get('score', 0)
            if not isinstance(name, str) or not (1 <= len(name.strip()) <= 64):
                return self.reply(400, {'error': 'name required (1..64 chars)'})
            if type(score) is not int or not (0 <= score <= 100000):
                return self.reply(400, {'error': 'score must be an integer 0..100000'})
        except (ValueError, TypeError, AttributeError, json.JSONDecodeError):
            return self.reply(400, {'error': 'invalid JSON'})
        try:
            with db_connection() as conn:
                with conn.cursor() as cur:
                    initialize(cur)
                    cur.execute('INSERT INTO players(name, score) VALUES (%s, %s) RETURNING id', (name.strip(), score))
                    new_id = cur.fetchone()[0]
            return self.reply(201, {'id': new_id, 'name': name.strip(), 'score': score})
        except Exception as ex:
            print(json.dumps({'event': 'db_error', 'error': type(ex).__name__}), flush=True)
            return self.reply(503, {'error': 'database unavailable'})


if __name__ == '__main__':
    port = int(os.getenv('PORT', '8080'))
    print(json.dumps({'event':'startup','port':port,'release':os.getenv('LAB_RELEASE','v1')}), flush=True)
    ThreadingHTTPServer(('0.0.0.0', port), Handler).serve_forever()
