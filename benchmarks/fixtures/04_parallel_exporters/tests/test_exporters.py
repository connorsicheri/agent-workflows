import unittest

from app.export import export_records


RECORDS = [
    {"name": "Ada", "role": "engineer"},
    {"name": "Lin", "role": "reviewer"},
]


class ExporterTests(unittest.TestCase):
    def test_json_is_compact_and_deterministic(self) -> None:
        self.assertEqual(
            export_records(RECORDS, "json"),
            '[{"name":"Ada","role":"engineer"},{"name":"Lin","role":"reviewer"}]',
        )

    def test_csv_has_one_header_and_lf_lines(self) -> None:
        self.assertEqual(
            export_records(RECORDS, "csv"),
            "name,role\nAda,engineer\nLin,reviewer\n",
        )

    def test_text_preserves_field_order(self) -> None:
        self.assertEqual(
            export_records(RECORDS, "text"),
            "name=Ada, role=engineer\nname=Lin, role=reviewer",
        )

    def test_empty_input_is_supported(self) -> None:
        self.assertEqual(export_records([], "json"), "[]")
        self.assertEqual(export_records([], "csv"), "")
        self.assertEqual(export_records([], "text"), "")

    def test_unknown_format_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            export_records(RECORDS, "xml")


if __name__ == "__main__":
    unittest.main()
