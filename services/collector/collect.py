"""Collect only permitted pages and persist an auditable raw snapshot."""
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib
import json

from .catalog import load_sources
from .policy import USER_AGENT, can_fetch


def collect_source(source_id: str) -> dict:
    source = next((item for item in load_sources() if item.id == source_id), None)
    if source is None:
        raise ValueError(f"Unknown source: {source_id}")
    if source.status != "active":
        return {"source": source.id, "status": "skipped", "reason": "source_not_active"}
    if not can_fetch(source.url):
        return {"source": source.id, "status": "blocked", "reason": "robots_disallow_or_unavailable"}

    request = Request(source.url, headers={"User-Agent": USER_AGENT, "Accept": "text/html"})
    with urlopen(request, timeout=20) as response:
        if response.status != 200:
            return {"source": source.id, "status": "failed", "reason": f"http_{response.status}"}
        body = response.read(2_000_000)
        content_type = response.headers.get_content_type()
    if content_type != "text/html":
        return {"source": source.id, "status": "failed", "reason": "unexpected_content_type"}

    observed_at = datetime.now(timezone.utc).isoformat()
    digest = hashlib.sha256(body).hexdigest()
    target = Path(__file__).parents[2] / "data" / "evidence" / source.id
    target.mkdir(parents=True, exist_ok=True)
    evidence = target / f"{digest}.html"
    evidence.write_bytes(body)
    manifest = {"source": source.id, "url": source.url, "observed_at": observed_at,
                "sha256": digest, "path": str(evidence), "bytes": len(body)}
    (target / f"{digest}.json").write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")
    return {"source": source.id, "status": "collected", **manifest}
