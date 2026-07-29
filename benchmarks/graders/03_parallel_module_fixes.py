from pathlib import Path
import sys


workspace = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(workspace))

from app.slug import slugify  # noqa: E402
from app.statistics import median  # noqa: E402
from app.windowing import chunked  # noqa: E402


assert slugify("API -- Rate___Limit") == "api-rate-limit"
assert slugify("***") == ""
assert median([-5, -1, 8, 10]) == 3.5
assert median([2.25]) == 2.25
assert chunked((value for value in range(7)), 3) == [[0, 1, 2], [3, 4, 5], [6]]
assert chunked([], 4) == []
print("hidden grader passed")
