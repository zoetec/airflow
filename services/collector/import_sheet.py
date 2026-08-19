"""Import and normalize the read-only source spreadsheet into the local catalog."""
import csv, io, json, re
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import urlopen

SHEET = 'https://docs.google.com/spreadsheets/d/1EWte5hKuazUt-dV4-whYqzETnn0gnt3trC9RhHp6AJ8/export?format=csv&gid=1438658535'
ROOT = Path(__file__).parents[2]

def normalize(value: str) -> str | None:
    match = re.search(r'(?:https?://)?(?:www\.)?[a-z0-9][a-z0-9.-]+\.[a-z]{2,}', value.lower())
    if not match: return None
    raw = match.group(0)
    return (urlparse(raw if raw.startswith('http') else 'https://' + raw).netloc or '').removeprefix('www.') or None

def run() -> dict:
    with urlopen(SHEET, timeout=20) as response:
        rows = list(csv.DictReader(io.TextIOWrapper(response, encoding='utf-8-sig')))
    path = ROOT / 'data' / 'sources.json'
    existing = {item.get('normalized_domain') or normalize(item['url']): item for item in json.loads(path.read_text(encoding='utf-8'))}
    output, seen, invalid, duplicates = [], set(), 0, 0
    for row in rows:
        domain = normalize(row.get('Site', ''))
        if not domain:
            invalid += 1; output.append({'id': 'invalid-' + str(invalid), 'name': row.get('Nome','Fonte'), 'url': row.get('Site',''), 'status':'invalid_url', 'city':'Florianópolis'}); continue
        if domain in seen:
            duplicates += 1; continue
        seen.add(domain)
        prior = existing.get(domain, {})
        output.append({'id': prior.get('id', re.sub(r'[^a-z0-9]+','-',domain).strip('-')), 'name': row.get('Nome','Fonte'), 'url': prior.get('url') or 'https://' + domain, 'status': prior.get('status','pending_review'), 'city':'Florianópolis', 'normalized_domain':domain})
    path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding='utf-8')
    return {'imported':len(output), 'invalid':invalid, 'duplicates':duplicates}

if __name__ == '__main__': print(run())
