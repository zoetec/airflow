"""Trust gate for candidates returned by an approved search-provider adapter."""
from urllib.parse import urlparse

DENYLIST = {"facebook.com", "instagram.com", "tiktok.com"}


def evaluate_candidate(url: str, city: str) -> dict:
    host = urlparse(url).netloc.lower().removeprefix("www.")
    if not host or host in DENYLIST:
        return {"url": url, "city": city, "status": "rejected", "reason": "unsupported_domain"}
    return {"url": url, "city": city, "status": "pending_review",
            "reason": "requires_terms_robots_and_sample_validation"}
