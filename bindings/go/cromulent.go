// Package cromulent is a Go port of the Cromulent PRNG.
//
// The Engine produces the identical 64-bit stream as the C reference
// implementation (cromulent_init / cromulent_next) for any given seed.
// StrongEngine mirrors the heavier cromulent_strong variant.
//
// The package is dependency-free apart from the standard library. All 64-bit
// arithmetic wraps naturally in Go, matching the C generator exactly.
package cromulent

import "math/bits"

const (
	c1  = 0x9e3779b97f4a7c15
	c2  = 0xbf58476d1ce4e5b9
	c3  = 0x94d049bb133111eb
	c6  = 0xd1342543de82ef95
	mh3 = 0xd6e8feb86659fd93

	// DefaultSeed is shared with the C library.
	DefaultSeed = 0x853c49e6748fea9b
)

func mixFast(x uint64) uint64 {
	x ^= x >> 32
	x *= mh3
	x ^= x >> 32
	return x
}

// seedStep is a SplitMix64-style seed expansion, matching cromulent_init.
func seedStep(z *uint64) uint64 {
	*z += c1
	*z = (*z ^ (*z >> 30)) * c2
	*z = (*z ^ (*z >> 27)) * c3
	return *z ^ (*z >> 31)
}

// Engine is the primary Cromulent generator.
type Engine struct {
	s0, s1 uint64
}

// New returns an Engine seeded from a single 64-bit value.
func New(seed uint64) *Engine {
	z := seed
	e := &Engine{}
	e.s0 = seedStep(&z)
	e.s1 = seedStep(&z)
	return e
}

// Next advances the state and returns the next 64-bit output.
func (e *Engine) Next() uint64 {
	s0 := e.s0
	s1 := e.s1

	e.s0 = s0*c6 + s1
	e.s1 = bits.RotateLeft64(s1, 31) + mixFast(s0)

	result := s0 + bits.RotateLeft64(s1, 11)
	result ^= result >> 27
	result *= c3
	result ^= result >> 27
	return result
}

// Float64 returns a uniform value in [0, 1) using the top 53 bits.
func (e *Engine) Float64() float64 {
	return float64(e.Next()>>11) * (1.0 / (1 << 53))
}

// Float32 returns a uniform value in [0, 1) using the top 24 bits.
func (e *Engine) Float32() float32 {
	return float32(e.Next()>>40) * (1.0 / (1 << 24))
}

// Bounded returns an unbiased uniform integer in [0, n) via Lemire's method.
// It returns 0 when n == 0.
func (e *Engine) Bounded(n uint64) uint64 {
	if n == 0 {
		return 0
	}
	hi, low := bits.Mul64(e.Next(), n)
	if low < n {
		threshold := (-n) % n
		for low < threshold {
			hi, low = bits.Mul64(e.Next(), n)
		}
	}
	return hi
}

// Discard advances the stream by z steps, discarding the output.
func (e *Engine) Discard(z uint64) {
	for ; z > 0; z-- {
		e.Next()
	}
}

// StrongEngine is the heavier "strong" Cromulent variant.
type StrongEngine struct {
	a, b uint64
}

// NewStrong returns a StrongEngine seeded from a single 64-bit value.
func NewStrong(seed uint64) *StrongEngine {
	z := seed
	e := &StrongEngine{}
	e.a = seedStep(&z)
	e.b = seedStep(&z)
	return e
}

// Next advances the state and returns the next 64-bit output.
func (e *StrongEngine) Next() uint64 {
	a := e.a
	b := e.b

	b += bits.RotateLeft64(a, 13)
	a = bits.RotateLeft64(a, 29)*c1 + b

	b = bits.RotateLeft64(b, 17) ^ a
	a += bits.RotateLeft64(b*c2, 31)

	b += bits.RotateLeft64(a, 23)
	a = bits.RotateLeft64(a^b, 52)

	output := a + bits.RotateLeft64(b, 41)

	e.a = a + c1
	e.b = b ^ (a >> 17)

	return mixFast(output)
}

// Discard advances the stream by z steps, discarding the output.
func (e *StrongEngine) Discard(z uint64) {
	for ; z > 0; z-- {
		e.Next()
	}
}
