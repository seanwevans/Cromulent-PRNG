require "spec"
require "../src/cromulent"

ENGINE_REF = [
  0x8b0849848b39737d_u64, 0x829ecfb661e3a84d_u64, 0x6cfb2afb89b5dc83_u64,
  0x8ad5c0d490669f95_u64, 0x8d4459e6318f2474_u64, 0xa0b907b845990f61_u64,
  0x2143675f2f4ff1ec_u64, 0x38fff6f9c33c4f8f_u64,
]

STRONG_REF = [
  0xa1e9fb73cc5c77fa_u64, 0xd8bc61a96accc72e_u64, 0x3f98dad0bcb1c8f3_u64,
  0xb179513c44fe1f0a_u64, 0x413b884be5b9955f_u64, 0x4b682d94916239a1_u64,
  0xe7b93a4600d77791_u64, 0x6a54f95b111a3555_u64,
]

describe Cromulent::Engine do
  it "matches the C reference" do
    e = Cromulent::Engine.new(0x0123456789ABCDEF_u64)
    ENGINE_REF.each { |want| e.next_u64.should eq(want) }
  end

  it "produces next_float in [0, 1)" do
    d = Cromulent::Engine.new(42_u64)
    (d.next_float - 0.42990649088115307).abs.should be < 1e-15
    10_000.times do
      v = d.next_float
      (v >= 0.0 && v < 1.0).should be_true
    end
  end

  it "produces bounded values in range" do
    b = Cromulent::Engine.new(99_u64)
    b.bounded(0_u64).should eq(0_u64)
    10_000.times { (b.bounded(7_u64) < 7_u64).should be_true }
  end

  it "discard(n) equals n calls" do
    a1 = Cromulent::Engine.new(555_u64)
    a2 = Cromulent::Engine.new(555_u64)
    a1.discard(50_u64)
    50.times { a2.next_u64 }
    (a1 == a2).should be_true
  end
end

describe Cromulent::StrongEngine do
  it "matches the C reference" do
    e = Cromulent::StrongEngine.new(0x0123456789ABCDEF_u64)
    STRONG_REF.each { |want| e.next_u64.should eq(want) }
  end
end
