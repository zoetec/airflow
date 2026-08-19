from datetime import datetime, timezone
from pathlib import Path
import json

ROOT = Path(__file__).parents[2]

def settings():
    return json.loads((ROOT / 'data' / 'settings.json').read_text(encoding='utf-8'))

def due():
    value = settings()
    last = value.get('last_updated')
    if not last:
        return True
    elapsed = datetime.now(timezone.utc) - datetime.fromisoformat(last.replace('Z', '+00:00'))
    return elapsed.total_seconds() >= int(value['collection_interval_hours']) * 3600

def mark_run():
    path = ROOT / 'data' / 'settings.json'
    value = settings()
    value['last_updated'] = datetime.now(timezone.utc).isoformat()
    path.write_text(json.dumps(value, ensure_ascii=False), encoding='utf-8')
