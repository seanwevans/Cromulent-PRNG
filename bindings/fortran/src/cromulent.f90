!> The Cromulent PRNG -- a modern Fortran (F2008) port of the scalar reference
!> generator.
!>
!> `cromulent_engine` reproduces the identical 64-bit stream as the C reference
!> implementation (cromulent_init / cromulent_next) for any given seed;
!> `strong_engine` mirrors the heavier cromulent_strong variant. Both are
!> derived types with type-bound procedures.
!>
!> Fortran integers are signed, but INT64 addition, multiplication, and the
!> bit intrinsics (IAND/IEOR/ISHFTC/SHIFTR) operate on the two's-complement bit
!> pattern and wrap exactly like the unsigned C generator (compile with
!> -fno-range-check so the 64-bit hex constants that set the high bit are
!> accepted). Values that must be interpreted as unsigned use the `ult` helper.
module cromulent
  use, intrinsic :: iso_fortran_env, only: int64, real64, real32
  implicit none
  private

  public :: cromulent_engine, strong_engine
  public :: make_engine, make_strong_engine
  public :: default_seed

  integer(int64), parameter :: C1  = int(z'9e3779b97f4a7c15', int64)
  integer(int64), parameter :: C2  = int(z'bf58476d1ce4e5b9', int64)
  integer(int64), parameter :: C3  = int(z'94d049bb133111eb', int64)
  integer(int64), parameter :: C6  = int(z'd1342543de82ef95', int64)
  integer(int64), parameter :: MH3 = int(z'd6e8feb86659fd93', int64)

  integer(int64), parameter :: MININT = int(z'8000000000000000', int64)
  integer(int64), parameter :: MASK32 = int(z'00000000ffffffff', int64)

  !> Default seed, shared with the C library.
  integer(int64), parameter :: default_seed = int(z'853c49e6748fea9b', int64)

  !> Primary Cromulent engine.
  type :: cromulent_engine
     integer(int64) :: s0 = 0_int64
     integer(int64) :: s1 = 0_int64
   contains
     procedure :: next        => engine_next
     procedure :: next_double => engine_next_double
     procedure :: next_float  => engine_next_float
     procedure :: bounded     => engine_bounded
     procedure :: discard     => engine_discard
  end type cromulent_engine

  !> Heavier "strong" Cromulent variant.
  type :: strong_engine
     integer(int64) :: a = 0_int64
     integer(int64) :: b = 0_int64
   contains
     procedure :: next    => strong_next
     procedure :: discard => strong_discard
  end type strong_engine

contains

  !> Unsigned less-than for 64-bit bit patterns.
  pure logical function ult(a, b)
    integer(int64), intent(in) :: a, b
    ult = ieor(a, MININT) < ieor(b, MININT)
  end function ult

  pure integer(int64) function mix_fast(x0) result(x)
    integer(int64), intent(in) :: x0
    x = ieor(x0, shiftr(x0, 32))
    x = x * MH3
    x = ieor(x, shiftr(x, 32))
  end function mix_fast

  !> SplitMix64-style seed expansion, matching cromulent_init.
  pure subroutine seed_expand(seed, v0, v1)
    integer(int64), intent(in)  :: seed
    integer(int64), intent(out) :: v0, v1
    integer(int64) :: z, out(2)
    integer :: i
    z = seed
    do i = 1, 2
       z = z + C1
       z = ieor(z, shiftr(z, 30)) * C2
       z = ieor(z, shiftr(z, 27)) * C3
       out(i) = ieor(z, shiftr(z, 31))
    end do
    v0 = out(1)
    v1 = out(2)
  end subroutine seed_expand

  !> High 64 bits of the unsigned 128-bit product a*b (32-bit limbs).
  pure integer(int64) function umul_high(a, b) result(hi)
    integer(int64), intent(in) :: a, b
    integer(int64) :: a_lo, a_hi, b_lo, b_hi
    integer(int64) :: lolo, hilo, lohi, hihi, carry
    a_lo = iand(a, MASK32); a_hi = shiftr(a, 32)
    b_lo = iand(b, MASK32); b_hi = shiftr(b, 32)
    lolo = a_lo * b_lo
    hilo = a_hi * b_lo
    lohi = a_lo * b_hi
    hihi = a_hi * b_hi
    carry = shiftr(shiftr(lolo, 32) + iand(hilo, MASK32) + iand(lohi, MASK32), 32)
    hi = hihi + shiftr(hilo, 32) + shiftr(lohi, 32) + carry
  end function umul_high

  !> 2^64 mod n (n treated as unsigned, n /= 0) == (-n) mod n. Computed by
  !> doubling with an overflow-free reduction, so it is correct for all n.
  pure integer(int64) function mod_two_pow64(n) result(r)
    integer(int64), intent(in) :: n
    integer(int64) :: d
    integer :: i
    if (n == 1_int64) then
       r = 0_int64
       return
    end if
    r = 1_int64
    do i = 1, 64
       d = n - r
       if (.not. ult(r, d)) then   ! r >= n - r  <=>  2r >= n
          r = r - d                ! = 2r - n, stays < n (no overflow)
       else
          r = r + r                ! 2r < n < 2^64 (exact)
       end if
    end do
  end function mod_two_pow64

  !> Construct an engine seeded from a single 64-bit value.
  pure type(cromulent_engine) function make_engine(seed) result(e)
    integer(int64), intent(in) :: seed
    call seed_expand(seed, e%s0, e%s1)
  end function make_engine

  !> Advance the state and return the next 64-bit output.
  integer(int64) function engine_next(self) result(r)
    class(cromulent_engine), intent(inout) :: self
    integer(int64) :: s0, s1
    s0 = self%s0
    s1 = self%s1
    self%s0 = s0 * C6 + s1
    self%s1 = ishftc(s1, 31) + mix_fast(s0)
    r = s0 + ishftc(s1, 11)
    r = ieor(r, shiftr(r, 27))
    r = r * C3
    r = ieor(r, shiftr(r, 27))
  end function engine_next

  !> Uniform double in [0, 1) using the top 53 bits.
  real(real64) function engine_next_double(self) result(d)
    class(cromulent_engine), intent(inout) :: self
    d = real(shiftr(self%next(), 11), real64) * (2.0_real64 ** (-53))
  end function engine_next_double

  !> Uniform single in [0, 1) using the top 24 bits.
  real(real32) function engine_next_float(self) result(f)
    class(cromulent_engine), intent(inout) :: self
    f = real(shiftr(self%next(), 40), real32) * (2.0_real32 ** (-24))
  end function engine_next_float

  !> Unbiased uniform integer in [0, n) via Lemire's method (n unsigned).
  !> Returns 0 when n == 0.
  integer(int64) function engine_bounded(self, n) result(res)
    class(cromulent_engine), intent(inout) :: self
    integer(int64), intent(in) :: n
    integer(int64) :: x, lo, hi, thr
    if (n == 0_int64) then
       res = 0_int64
       return
    end if
    x = self%next()
    lo = x * n
    hi = umul_high(x, n)
    if (ult(lo, n)) then
       thr = mod_two_pow64(n)
       do while (ult(lo, thr))
          x = self%next()
          lo = x * n
          hi = umul_high(x, n)
       end do
    end if
    res = hi
  end function engine_bounded

  !> Advance the stream by z steps, discarding the output.
  subroutine engine_discard(self, z)
    class(cromulent_engine), intent(inout) :: self
    integer(int64), intent(in) :: z
    integer(int64) :: i
    integer(int64) :: dummy
    do i = 1_int64, z
       dummy = self%next()
    end do
  end subroutine engine_discard

  !> Construct a strong engine seeded from a single 64-bit value.
  pure type(strong_engine) function make_strong_engine(seed) result(e)
    integer(int64), intent(in) :: seed
    call seed_expand(seed, e%a, e%b)
  end function make_strong_engine

  integer(int64) function strong_next(self) result(output)
    class(strong_engine), intent(inout) :: self
    integer(int64) :: a, b
    a = self%a
    b = self%b
    b = b + ishftc(a, 13)
    a = ishftc(a, 29) * C1 + b
    b = ieor(ishftc(b, 17), a)
    a = a + ishftc(b * C2, 31)
    b = b + ishftc(a, 23)
    a = ishftc(ieor(a, b), 52)
    output = a + ishftc(b, 41)
    self%a = a + C1
    self%b = ieor(b, shiftr(a, 17))
    output = mix_fast(output)
  end function strong_next

  subroutine strong_discard(self, z)
    class(strong_engine), intent(inout) :: self
    integer(int64), intent(in) :: z
    integer(int64) :: i
    integer(int64) :: dummy
    do i = 1_int64, z
       dummy = self%next()
    end do
  end subroutine strong_discard

end module cromulent
