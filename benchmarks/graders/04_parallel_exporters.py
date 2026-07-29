from pathlib import Path
import sys


workspace = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(workspace))

from app.export import export_records  # noqa: E402


records = [
    {"z": "last", "a": "first,with-comma"},
    {"z": "line", "a": 'quote"value'},
]

assert export_records(records, "json") == (
    '[{"a":"first,with-comma","z":"last"},'
    '{"a":"quote\\\"value","z":"line"}]'
)
assert export_records(records, "csv") == (
    'z,a\nlast,"first,with-comma"\nline,"quote""value"\n'
)
assert export_records(records, "text") == (
    'z=last, a=first,with-comma\nz=line, a=quote"value'
)
print("hidden grader passed")
