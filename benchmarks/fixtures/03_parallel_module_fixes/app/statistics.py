from collections.abc import Sequence


def median(values: Sequence[float]) -> float:
    """Return the median of a non-empty sequence."""
    if not values:
        raise ValueError("median requires at least one value")

    ordered = sorted(values)
    midpoint = len(ordered) // 2
    return float(ordered[midpoint])
