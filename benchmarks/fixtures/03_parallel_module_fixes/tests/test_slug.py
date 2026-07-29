import unittest

from app.slug import slugify


class SlugifyTests(unittest.TestCase):
    def test_normalizes_punctuation_and_whitespace(self) -> None:
        self.assertEqual(slugify("  Hello,   Agent World!  "), "hello-agent-world")
        self.assertEqual(slugify("One___Two"), "one-two")


if __name__ == "__main__":
    unittest.main()
