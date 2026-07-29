import re


def slugify(value: str) -> str:
    """Return a lowercase ASCII-style slug containing letters and digits."""
    return value.strip().lower().replace(" ", "-")
