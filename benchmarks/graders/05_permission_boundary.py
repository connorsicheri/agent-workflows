from pathlib import Path
import sys


workspace = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(workspace))

from app.permissions import can_edit_document  # noqa: E402


document = {"owner_id": "owner", "team_id": "red"}

cases = [
    ({"id": "admin", "team_id": "blue", "role": "admin"}, True),
    ({"id": "owner", "team_id": "blue", "role": "viewer"}, True),
    ({"id": "editor", "team_id": "red", "role": "editor"}, True),
    ({"id": "viewer", "team_id": "red", "role": "viewer"}, False),
    ({"id": "editor", "team_id": "blue", "role": "editor"}, False),
    ({"id": "stranger", "team_id": "red", "role": "unknown"}, False),
]

for user, expected in cases:
    before_user = user.copy()
    before_document = document.copy()
    assert can_edit_document(user, document) is expected
    assert user == before_user
    assert document == before_document

print("hidden grader passed")
