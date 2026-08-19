"""Network policy: robots.txt is authoritative and failures are safe failures."""
from urllib.parse import urlparse
from urllib.robotparser import RobotFileParser

USER_AGENT = "RotaDeCasaCatalogBot/0.1 (+contact@rotadecasa.invalid)"


def can_fetch(url: str) -> bool:
    parsed = urlparse(url)
    robots = RobotFileParser()
    robots.set_url(f"{parsed.scheme}://{parsed.netloc}/robots.txt")
    try:
        robots.read()
    except OSError:
        return False
    return robots.can_fetch(USER_AGENT, url)
