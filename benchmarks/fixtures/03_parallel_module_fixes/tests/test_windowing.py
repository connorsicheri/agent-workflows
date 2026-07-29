import unittest

from app.windowing import chunked


class ChunkedTests(unittest.TestCase):
    def test_retains_partial_chunk(self) -> None:
        self.assertEqual(chunked(range(5), 2), [[0, 1], [2, 3], [4]])

    def test_rejects_invalid_size(self) -> None:
        with self.assertRaises(ValueError):
            chunked([1], 0)


if __name__ == "__main__":
    unittest.main()
