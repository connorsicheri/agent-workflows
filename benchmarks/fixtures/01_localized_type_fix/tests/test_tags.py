import unittest
from typing import get_type_hints

from app.tags import normalize_tags


class NormalizeTagsTests(unittest.TestCase):
    def test_normalizes_and_deduplicates_in_order(self) -> None:
        self.assertEqual(
            normalize_tags([" Beta ", "alpha", "BETA", "", "Alpha"]),
            ["beta", "alpha"],
        )

    def test_declares_list_return_type(self) -> None:
        self.assertEqual(get_type_hints(normalize_tags)["return"], list[str])


if __name__ == "__main__":
    unittest.main()
