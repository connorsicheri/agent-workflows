import unittest

from app.pagination import paginate


class PaginationTests(unittest.TestCase):
    def test_returns_one_based_pages(self) -> None:
        items = ["a", "b", "c", "d", "e"]
        self.assertEqual(paginate(items, 1, 2), ["a", "b"])
        self.assertEqual(paginate(items, 2, 2), ["c", "d"])
        self.assertEqual(paginate(items, 3, 2), ["e"])

    def test_page_beyond_data_is_empty(self) -> None:
        self.assertEqual(paginate([1, 2], 3, 2), [])

    def test_rejects_invalid_arguments(self) -> None:
        with self.assertRaises(ValueError):
            paginate([1], 0, 1)
        with self.assertRaises(ValueError):
            paginate([1], 1, 0)


if __name__ == "__main__":
    unittest.main()
