import random
import unittest

def signed8(value):
    value &= 0xff
    return value - 256 if value >= 128 else value

def wrap_int32(value):
    value &= 0xffffffff
    return value - 0x100000000 if value >= 0x80000000 else value

def gemm4x4(a, b):
    return [[wrap_int32(sum(signed8(a[r][k]) * signed8(b[k][c]) for k in range(4)))
             for c in range(4)] for r in range(4)]

class TestApuGemmReference(unittest.TestCase):
    def test_known_matrix(self):
        a = [[1,2,3,4],[-1,2,-3,4],[5,0,-2,1],[127,-128,1,-1]]
        b = [[1,2,0,-1],[0,1,2,3],[3,0,-1,2],[-2,1,1,0]]
        self.assertEqual(gemm4x4(a,b), [[2,8,5,11],[-18,4,11,1],[-3,11,3,-9],[132,125,-258,-509]])

    def test_signed_int8_extremes(self):
        a = [[-128]*4 for _ in range(4)]
        b = [[-128]*4 for _ in range(4)]
        self.assertEqual(gemm4x4(a,b), [[65536]*4 for _ in range(4)])

    def test_int32_wraparound(self):
        self.assertEqual(wrap_int32(0x7fffffff+1), -0x80000000)
        self.assertEqual(wrap_int32(-0x80000000-1), 0x7fffffff)

    def test_deterministic_random_matrix(self):
        rng = random.Random(20261115)
        a = [[rng.randint(-128,127) for _ in range(4)] for _ in range(4)]
        b = [[rng.randint(-128,127) for _ in range(4)] for _ in range(4)]
        result = gemm4x4(a,b)
        self.assertEqual((len(result),len(result[0])), (4,4))

if __name__ == "__main__":
    unittest.main()
