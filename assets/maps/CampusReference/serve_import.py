"""Local, bounded asset handoff between Blender exports and Studio MCP."""
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path
import json,mimetypes
ROOT=Path(__file__).resolve().parent/'roblox_staging'
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        p=(ROOT/self.path.lstrip('/')).resolve()
        if not p.is_relative_to(ROOT.resolve()) or not p.is_file():
            self.send_error(404);return
        data=p.read_bytes();self.send_response(200);self.send_header('Content-Type',mimetypes.guess_type(str(p))[0] or 'application/octet-stream');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
    def do_POST(self):
        if self.path!='/assets':self.send_error(404);return
        row=json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        with (ROOT/'uploaded_assets.jsonl').open('a',encoding='utf-8') as f:f.write(json.dumps(row)+'\n')
        self.send_response(200);self.end_headers();self.wfile.write(b'{}')
ThreadingHTTPServer(('127.0.0.1',8766),Handler).serve_forever()
