import unittest

from app.statistics import median


class MedianTests(unittest.TestCase):
    def test_odd_and_even_lengths(self) -> None:
        self.assertEqual(median([9, 1, 5]), 5.0)
        self.assertEqual(median([10, 2, 4, 8]), 6.0)

    def test_rejects_empty_input(self) -> None:
        with self.assertRaises(ValueError):
            median([])


if __name__ == "__main__":
    unittest.main()
