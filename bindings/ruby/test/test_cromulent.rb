# frozen_string_literal: true

require_relative "../lib/cromulent"

ENGINE_REF = [
  0x8b0849848b39737d, 0x829ecfb661e3a84d, 0x6cfb2afb89b5dc83,
  0x8ad5c0d490669f95, 0x8d4459e6318f2474, 0xa0b907b845990f61,
  0x2143675f2f4ff1ec, 0x38fff6f9c33c4f8f
].freeze

STRONG_REF = [
  0xa1e9fb73cc5c77fa, 0xd8bc61a96accc72e, 0x3f98dad0bcb1c8f3,
  0xb179513c44fe1f0a, 0x413b884be5b9955f, 0x4b682d94916239a1,
  0xe7b93a4600d77791, 0x6a54f95b111a3555
].freeze

$failures = 0

def check(cond, msg)
  return if cond

  warn "FAIL: #{msg}"
  $failures += 1
end

puts "Running Cromulent Ruby engine tests"

print "Testing engine matches C reference... "
e = Cromulent::Engine.new(0x0123456789ABCDEF)
ENGINE_REF.each_with_index { |want, i| check(e.next_u64 == want, "engine output #{i}") }
puts "OK"

print "Testing strong engine matches C reference... "
s = Cromulent::StrongEngine.new(0x0123456789ABCDEF)
STRONG_REF.each_with_index { |want, i| check(s.next_u64 == want, "strong output #{i}") }
puts "OK"

print "Testing next_float range... "
d = Cromulent::Engine.new(42)
check((d.next_float - 0.42990649088115307).abs < 1e-15, "first double")
10_000.times do
  v = d.next_float
  check(v >= 0.0 && v < 1.0, "double in range")
end
puts "OK"

print "Testing bounded... "
b = Cromulent::Engine.new(99)
check(b.bounded(0) == 0, "bounded(0)")
10_000.times { check(b.bounded(7) < 7, "bounded(7) < 7") }
puts "OK"

print "Testing discard equivalence... "
a1 = Cromulent::Engine.new(555)
a2 = Cromulent::Engine.new(555)
a1.discard(50)
50.times { a2.next_u64 }
check(a1 == a2, "discard(n) == n calls")
puts "OK"

if $failures.zero?
  puts "All Ruby engine tests passed successfully!"
  exit 0
else
  puts "#{$failures} check(s) failed!"
  exit 1
end
