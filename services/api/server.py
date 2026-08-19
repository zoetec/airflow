from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
ROOT=Path('/app') if Path('/app').exists() else Path(__file__).parents[2]
SETTINGS=ROOT/'data'/'settings.json'
class Handler(SimpleHTTPRequestHandler):
    def __init__(self,*a,**kw): super().__init__(*a,directory=str(ROOT/'apps'/'web'),**kw)
    def do_GET(self):
        if self.path=='/api/settings':
            self.send_response(200);self.send_header('Content-Type','application/json');self.end_headers();self.wfile.write(SETTINGS.read_bytes());return
        super().do_GET()
    def do_PUT(self):
        if self.path!='/api/settings': self.send_error(404);return
        try:
            value=json.loads(self.rfile.read(int(self.headers['Content-Length']))); hours=int(value['collection_interval_hours']); assert hours in (6,12,24,168)
            current=json.loads(SETTINGS.read_text());current['collection_interval_hours']=hours;SETTINGS.write_text(json.dumps(current));self.send_response(204);self.end_headers()
        except Exception: self.send_error(400)
ThreadingHTTPServer(('0.0.0.0',3000),Handler).serve_forever()
