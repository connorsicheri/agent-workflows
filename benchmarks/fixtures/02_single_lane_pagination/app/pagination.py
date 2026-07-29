from collections.abc import Sequence
from typing import TypeVar


T = TypeVar("T")


def paginate(items: Sequence[T], page: int, page_size: int) -> list[T]:
    """Return one one-based page of items."""
    if page < 1:
        raise ValueError("page must be at least 1")
    if page_size < 1:
        raise ValueError("page_size must be at least 1")

    start = page * page_size
    return list(items[start : start + page_size])
