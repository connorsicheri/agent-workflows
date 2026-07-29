from typing import TypedDict


class User(TypedDict):
    id: str
    team_id: str
    role: str


class Document(TypedDict):
    owner_id: str
    team_id: str


def can_edit_document(user: User, document: Document) -> bool:
    """Return whether a user may edit a document."""
    if user["role"] == "admin":
        return True
    if user["team_id"] == document["team_id"]:
        return True
    return user["id"] == document["owner_id"]
