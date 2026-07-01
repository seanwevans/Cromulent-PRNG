"""Tests for the pure-Python Cromulent port.

Run with ``python -m unittest`` (or ``pytest``) from this directory.
"""

import unittest

from cromulent import Engine, StrongEngine

ENGINE_REF = [
    0x8B0849848B39737D,
    0x829ECFB661E3A84D,
    0x6CFB2AFB89B5DC83,
    0x8AD5C0D490669F95,
    0x8D4459E6318F2474,
    0xA0B907B845990F61,
    0x2143675F2F4FF1EC,
    0x38FFF6F9C33C4F8F,
]

STRONG_REF = [
    0xA1E9FB73CC5C77FA,
    0xD8BC61A96ACCC72E,
    0x3F98DAD0BCB1C8F3,
    0xB179513C44FE1F0A,
    0x413B884BE5B9955F,
    0x4B682D94916239A1,
    0xE7B93A4600D77791,
    0x6A54F95B111A3555,
]


class TestCromulent(unittest.TestCase):
    def test_matches_reference(self):
        e = Engine(0x0123456789ABCDEF)
        for want in ENGINE_REF:
            self.assertEqual(e.next_u64(), want)

    def test_strong_matches_reference(self):
        e = StrongEngine(0x0123456789ABCDEF)
        for want in STRONG_REF:
            self.assertEqual(e.next_u64(), want)

    def test_outputs_are_64_bit(self):
        e = Engine(1)
        for _ in range(1000):
            self.assertTrue(0 <= e.next_u64() < (1 << 64))

    def test_random_range(self):
        e = Engine(42)
        self.assertAlmostEqual(e.random(), 0.42990649088115307, places=15)
        for _ in range(10000):
            d = e.random()
            self.assertTrue(0.0 <= d < 1.0)

    def test_bounded(self):
        e = Engine(99)
        self.assertEqual(e.bounded(0), 0)
        for _ in range(10000):
            self.assertLess(e.bounded(7), 7)

    def test_discard_equivalence(self):
        a = Engine(555)
        b = Engine(555)
        a.discard(50)
        for _ in range(50):
            b.next_u64()
        self.assertEqual(a, b)


if __name__ == "__main__":
    unittest.main()
