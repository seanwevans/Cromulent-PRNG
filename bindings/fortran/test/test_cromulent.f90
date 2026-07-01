!> Self-contained test for the Fortran Cromulent port. Verifies bit-for-bit
!> parity with the C reference vectors and basic range/discard behavior.
!> Uses `error stop` (non-zero exit) on failure.
program test_cromulent
  use, intrinsic :: iso_fortran_env, only: int64, real64
  use cromulent
  implicit none

  integer(int64), parameter :: MININT = int(z'8000000000000000', int64)
  integer(int64) :: eref(8), sref(8)
  type(cromulent_engine) :: e, a, b
  type(strong_engine) :: s
  integer :: i
  integer :: fails
  real(real64) :: d

  eref = [ int(z'8b0849848b39737d', int64), int(z'829ecfb661e3a84d', int64), &
           int(z'6cfb2afb89b5dc83', int64), int(z'8ad5c0d490669f95', int64), &
           int(z'8d4459e6318f2474', int64), int(z'a0b907b845990f61', int64), &
           int(z'2143675f2f4ff1ec', int64), int(z'38fff6f9c33c4f8f', int64) ]

  sref = [ int(z'a1e9fb73cc5c77fa', int64), int(z'd8bc61a96accc72e', int64), &
           int(z'3f98dad0bcb1c8f3', int64), int(z'b179513c44fe1f0a', int64), &
           int(z'413b884be5b9955f', int64), int(z'4b682d94916239a1', int64), &
           int(z'e7b93a4600d77791', int64), int(z'6a54f95b111a3555', int64) ]

  fails = 0

  write(*,'(a)') 'Running Cromulent Fortran engine tests'

  ! Engine parity
  write(*,'(a)', advance='no') 'Testing engine matches C reference... '
  e = make_engine(int(z'0123456789ABCDEF', int64))
  do i = 1, 8
     call check(e%next() == eref(i), 'engine output')
  end do
  write(*,'(a)') 'OK'

  ! Strong parity
  write(*,'(a)', advance='no') 'Testing strong engine matches C reference... '
  s = make_strong_engine(int(z'0123456789ABCDEF', int64))
  do i = 1, 8
     call check(s%next() == sref(i), 'strong output')
  end do
  write(*,'(a)') 'OK'

  ! Double range
  write(*,'(a)', advance='no') 'Testing next_double range... '
  e = make_engine(42_int64)
  d = e%next_double()
  call check(abs(d - 0.42990649088115307_real64) < 1.0e-15_real64, 'first double')
  do i = 1, 10000
     d = e%next_double()
     call check(d >= 0.0_real64 .and. d < 1.0_real64, 'double in range')
  end do
  write(*,'(a)') 'OK'

  ! Bounded range
  write(*,'(a)', advance='no') 'Testing bounded()... '
  e = make_engine(99_int64)
  call check(e%bounded(0_int64) == 0_int64, 'bounded(0)')
  do i = 1, 10000
     call check(ult_local(e%bounded(7_int64), 7_int64), 'bounded(7) < 7')
  end do
  write(*,'(a)') 'OK'

  ! Discard equivalence
  write(*,'(a)', advance='no') 'Testing discard equivalence... '
  a = make_engine(555_int64)
  b = make_engine(555_int64)
  call a%discard(50_int64)
  do i = 1, 50
     call check_advance(b)
  end do
  do i = 1, 100
     call check(a%next() == b%next(), 'discard(n) == n calls')
  end do
  write(*,'(a)') 'OK'

  if (fails == 0) then
     write(*,'(a)') 'All Fortran engine tests passed successfully!'
  else
     write(*,'(i0,a)') fails, ' check(s) failed!'
     error stop 1
  end if

contains

  subroutine check(cond, msg)
    logical, intent(in) :: cond
    character(*), intent(in) :: msg
    if (.not. cond) then
       write(*,'(a,a)') 'FAIL: ', msg
       fails = fails + 1
    end if
  end subroutine check

  subroutine check_advance(eng)
    type(cromulent_engine), intent(inout) :: eng
    integer(int64) :: dummy
    dummy = eng%next()
  end subroutine check_advance

  pure logical function ult_local(x, y)
    integer(int64), intent(in) :: x, y
    ult_local = ieor(x, MININT) < ieor(y, MININT)
  end function ult_local

end program test_cromulent
