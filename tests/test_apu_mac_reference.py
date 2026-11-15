import unittest


def int8(x):
    """Interpret an integer as signed 8-bit two's-complement."""
    x &= 0xff
    return x - 256 if x >= 128 else x


def mac_step(acc, a, b, clear=False):
    product = int8(a) * int8(b)
    value = product if clear else acc + product
    value &= 0xffffffff
    return value - 0x100000000 if value >= 0x80000000 else value


class TestApuMacReference(unittest.TestCase):
    def test_positive_product(self):
        self.assertEqual(mac_step(0, 3, 4, True), 12)

    def test_signed_accumulation(self):
        self.assertEqual(mac_step(12, -2, 5), 2)

    def test_clear_replaces_accumulator(self):
        self.assertEqual(mac_step(999, 7, 6, True), 42)

    def test_int8_extremes(self):
        self.assertEqual(mac_step(0, -128, -128, True), 16384)
        self.assertEqual(mac_step(0, -128, 127, True), -16256)

    def test_int32_wraparound(self):
        self.assertEqual(mac_step(0x7fffffff, 1, 1), -0x80000000)


if __name__ == "__main__":
    unittest.main()
