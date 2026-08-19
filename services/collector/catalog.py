from dataclasses import dataclass
from pathlib import Path
import json


@dataclass(frozen=True)
class Source:
    id: str
    name: str
    url: str
    status: str
    city: str = "Florianópolis"


def load_sources() -> list[Source]:
    path = Path(__file__).parents[2] / "data" / "sources.json"
    return [Source(**item) for item in json.loads(path.read_text(encoding="utf-8"))]
