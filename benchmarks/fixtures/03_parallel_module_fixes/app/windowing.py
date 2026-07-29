from collections.abc import Iterable
from typing import TypeVar


T = TypeVar("T")


def chunked(values: Iterable[T], size: int) -> list[list[T]]:
    """Split values into chunks, retaining the final partial chunk."""
    if size < 1:
        raise ValueError("size must be at least 1")

    chunks: list[list[T]] = []
    current: list[T] = []
    for value in values:
        current.append(value)
        if len(current) == size:
            chunks.append(current)
            current = []
    return chunks
