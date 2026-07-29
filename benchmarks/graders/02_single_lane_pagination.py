from pathlib import Path
import sys


workspace = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(workspace))

from app.pagination import paginate  # noqa: E402


values = tuple(range(10))
assert paginate(values, 1, 3) == [0, 1, 2]
assert paginate(values, 4, 3) == [9]
assert paginate(values, 5, 3) == []

for page, size in ((-1, 2), (1, -1)):
    try:
        paginate(values, page, size)
    except ValueError:
        pass
    else:
        raise AssertionError("invalid pagination arguments must raise ValueError")

print("hidden grader passed")
