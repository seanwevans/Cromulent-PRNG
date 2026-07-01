package cromulent

import "testing"

var engineRef = [8]uint64{
	0x8b0849848b39737d,
	0x829ecfb661e3a84d,
	0x6cfb2afb89b5dc83,
	0x8ad5c0d490669f95,
	0x8d4459e6318f2474,
	0xa0b907b845990f61,
	0x2143675f2f4ff1ec,
	0x38fff6f9c33c4f8f,
}

var strongRef = [8]uint64{
	0xa1e9fb73cc5c77fa,
	0xd8bc61a96accc72e,
	0x3f98dad0bcb1c8f3,
	0xb179513c44fe1f0a,
	0x413b884be5b9955f,
	0x4b682d94916239a1,
	0xe7b93a4600d77791,
	0x6a54f95b111a3555,
}

func TestMatchesReference(t *testing.T) {
	e := New(0x0123456789ABCDEF)
	for i, want := range engineRef {
		if got := e.Next(); got != want {
			t.Fatalf("output %d: got %#016x want %#016x", i, got, want)
		}
	}
}

func TestStrongMatchesReference(t *testing.T) {
	e := NewStrong(0x0123456789ABCDEF)
	for i, want := range strongRef {
		if got := e.Next(); got != want {
			t.Fatalf("strong output %d: got %#016x want %#016x", i, got, want)
		}
	}
}

func TestFloat64Range(t *testing.T) {
	e := New(42)
	if got := e.Float64(); got < 0.4299064908 || got > 0.4299064909 {
		t.Fatalf("first double: got %.17g", got)
	}
	for i := 0; i < 10000; i++ {
		if d := e.Float64(); d < 0 || d >= 1 {
			t.Fatalf("double out of range: %.17g", d)
		}
	}
}

func TestBounded(t *testing.T) {
	e := New(99)
	if e.Bounded(0) != 0 {
		t.Fatal("Bounded(0) must be 0")
	}
	for i := 0; i < 10000; i++ {
		if v := e.Bounded(7); v >= 7 {
			t.Fatalf("Bounded(7) out of range: %d", v)
		}
	}
}

func TestDiscardEquivalence(t *testing.T) {
	a := New(555)
	b := New(555)
	a.Discard(50)
	for i := 0; i < 50; i++ {
		b.Next()
	}
	if *a != *b {
		t.Fatal("Discard(n) must equal n calls")
	}
}
