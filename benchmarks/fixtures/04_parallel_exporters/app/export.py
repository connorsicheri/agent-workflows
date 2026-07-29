from collections.abc import Sequence

from app.exporters.csv_exporter import export_csv
from app.exporters.json_exporter import export_json
from app.exporters.text_exporter import export_text


Record = dict[str, str]


def export_records(records: Sequence[Record], output_format: str) -> str:
    """Export records using one supported deterministic format."""
    exporters = {
        "csv": export_csv,
        "json": export_json,
        "text": export_text,
    }
    try:
        exporter = exporters[output_format]
    except KeyError as exc:
        raise ValueError(f"unsupported format: {output_format}") from exc
    return exporter(records)
