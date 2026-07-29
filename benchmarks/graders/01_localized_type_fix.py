from pathlib import Path
import sys
from typing import get_type_hints


workspace = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(workspace))

from app.tags import normalize_tags  # noqa: E402


assert get_type_hints(normalize_tags)["return"] == list[str]
assert normalize_tags(tag for tag in [" A ", "a", "B", " "]) == ["a", "b"]
assert normalize_tags([]) == []
print("hidden grader passed")
