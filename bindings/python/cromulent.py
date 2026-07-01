"""The Cromulent PRNG — a pure-Python port of the scalar reference generator.

``Engine`` produces the identical 64-bit stream as the C reference
implementation (``cromulent_init`` / ``cromulent_next``) for any given seed.
``StrongEngine`` mirrors the heavier ``cromulent_strong`` variant.

Python integers are arbitrary precision, so every operation is masked back to
64 bits with ``_MASK`` to reproduce the wrapping arithmetic of the C generator.
"""

from __future__ import annotations

__all__ = ["Engine", "StrongEngine", "DEFAULT_SEED"]

_MASK = (1 << 64) - 1

_C1 = 0x9E3779B97F4A7C15
_C2 = 0xBF58476D1CE4E5B9
_C3 = 0x94D049BB133111EB
_C6 = 0xD1342543DE82EF95
_MH3 = 0xD6E8FEB86659FD93

#: Default seed, shared with the C library.
DEFAULT_SEED = 0x853C49E6748FEA9B


def _rotl(x: int, k: int) -> int:
    return ((x << k) | (x >> (64 - k))) & _MASK


def _mix_fast(x: int) -> int:
    x ^= x >> 32
    x = (x * _MH3) & _MASK
    x ^= x >> 32
    return x


def _seed_expand(seed: int) -> tuple[int, int]:
    """SplitMix64-style seed expansion, matching cromulent_init."""
    z = seed & _MASK
    out = []
    for _ in range(2):
        z = (z + _C1) & _MASK
        z = ((z ^ (z >> 30)) * _C2) & _MASK
        z = ((z ^ (z >> 27)) * _C3) & _MASK
        out.append(z ^ (z >> 31))
    return out[0], out[1]


class Engine:
    """The primary Cromulent generator."""

    __slots__ = ("_s0", "_s1")

    def __init__(self, seed: int = DEFAULT_SEED) -> None:
        self._s0, self._s1 = _seed_expand(seed)

    def next_u64(self) -> int:
        """Advance the state and return the next 64-bit output."""
        s0 = self._s0
        s1 = self._s1

        self._s0 = (s0 * _C6 + s1) & _MASK
        self._s1 = (_rotl(s1, 31) + _mix_fast(s0)) & _MASK

        result = (s0 + _rotl(s1, 11)) & _MASK
        result ^= result >> 27
        result = (result * _C3) & _MASK
        result ^= result >> 27
        return result

    def random(self) -> float:
        """Uniform float in [0, 1) using the top 53 bits."""
        return (self.next_u64() >> 11) * (1.0 / (1 << 53))

    def next_float(self) -> float:
        """Uniform float in [0, 1) using the top 24 bits (single precision)."""
        return (self.next_u64() >> 40) * (1.0 / (1 << 24))

    def bounded(self, n: int) -> int:
        """Unbiased uniform integer in [0, n) via Lemire's method.

        Returns 0 when ``n == 0``.
        """
        if n == 0:
            return 0
        m = self.next_u64() * n
        low = m & _MASK
        if low < n:
            threshold = (-n) % n
            while low < threshold:
                m = self.next_u64() * n
                low = m & _MASK
        return m >> 64

    def discard(self, z: int) -> None:
        """Advance the stream by ``z`` steps, discarding the output."""
        for _ in range(z):
            self.next_u64()

    def __iter__(self):
        return self

    def __next__(self) -> int:
        return self.next_u64()

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Engine):
            return NotImplemented
        return self._s0 == other._s0 and self._s1 == other._s1


class StrongEngine:
    """The heavier "strong" Cromulent variant."""

    __slots__ = ("_a", "_b")

    def __init__(self, seed: int = DEFAULT_SEED) -> None:
        self._a, self._b = _seed_expand(seed)

    def next_u64(self) -> int:
        """Advance the state and return the next 64-bit output."""
        a = self._a
        b = self._b

        b = (b + _rotl(a, 13)) & _MASK
        a = (_rotl(a, 29) * _C1 + b) & _MASK

        b = _rotl(b, 17) ^ a
        a = (a + _rotl((b * _C2) & _MASK, 31)) & _MASK

        b = (b + _rotl(a, 23)) & _MASK
        a = _rotl(a ^ b, 52)

        output = (a + _rotl(b, 41)) & _MASK

        self._a = (a + _C1) & _MASK
        self._b = b ^ (a >> 17)

        return _mix_fast(output)

    def discard(self, z: int) -> None:
        for _ in range(z):
            self.next_u64()

    def __iter__(self):
        return self

    def __next__(self) -> int:
        return self.next_u64()

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, StrongEngine):
            return NotImplemented
        return self._a == other._a and self._b == other._b
