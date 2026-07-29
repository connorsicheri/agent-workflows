from collections.abc import Sequence


Record = dict[str, str]


def export_text(records: Sequence[Record]) -> str:
    """Return lines of comma-separated key=value pairs in field order."""
    raise NotImplementedError
