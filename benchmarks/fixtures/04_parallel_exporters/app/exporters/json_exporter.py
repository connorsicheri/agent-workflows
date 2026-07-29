from collections.abc import Sequence


Record = dict[str, str]


def export_json(records: Sequence[Record]) -> str:
    """Return compact JSON with object keys sorted for deterministic output."""
    raise NotImplementedError
