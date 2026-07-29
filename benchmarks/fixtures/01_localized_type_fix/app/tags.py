from collections.abc import Iterable


def normalize_tags(tags: Iterable[str]) -> str:
    """Return normalized, non-empty tags once in first-seen order."""
    normalized: list[str] = []
    seen: set[str] = set()

    for tag in tags:
        value = tag.strip().lower()
        if value and value not in seen:
            seen.add(value)
            normalized.append(value)

    return normalized
