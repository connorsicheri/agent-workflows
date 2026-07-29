from collections.abc import Sequence


Record = dict[str, str]


def export_csv(records: Sequence[Record]) -> str:
    """Return CSV using first-record field order, one header, and LF lines."""
    raise NotImplementedError
