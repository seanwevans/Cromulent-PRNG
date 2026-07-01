// Tests for the JavaScript Cromulent port.
// Run with: node --test   (Node 18+)

import { test } from "node:test";
import assert from "node:assert/strict";
import { Engine, StrongEngine } from "./cromulent.mjs";

const ENGINE_REF = [
  0x8b0849848b39737dn,
  0x829ecfb661e3a84dn,
  0x6cfb2afb89b5dc83n,
  0x8ad5c0d490669f95n,
  0x8d4459e6318f2474n,
  0xa0b907b845990f61n,
  0x2143675f2f4ff1ecn,
  0x38fff6f9c33c4f8fn,
];

const STRONG_REF = [
  0xa1e9fb73cc5c77fan,
  0xd8bc61a96accc72en,
  0x3f98dad0bcb1c8f3n,
  0xb179513c44fe1f0an,
  0x413b884be5b9955fn,
  0x4b682d94916239a1n,
  0xe7b93a4600d77791n,
  0x6a54f95b111a3555n,
];

test("matches C reference", () => {
  const e = new Engine(0x0123456789abcdefn);
  for (const want of ENGINE_REF) assert.equal(e.nextU64(), want);
});

test("strong matches C reference", () => {
  const e = new StrongEngine(0x0123456789abcdefn);
  for (const want of STRONG_REF) assert.equal(e.nextU64(), want);
});

test("outputs are 64-bit", () => {
  const e = new Engine(1n);
  for (let i = 0; i < 1000; i++) {
    const v = e.nextU64();
    assert.ok(v >= 0n && v < 1n << 64n);
  }
});

test("nextDouble in range", () => {
  const e = new Engine(42n);
  assert.ok(Math.abs(e.nextDouble() - 0.42990649088115307) < 1e-15);
  for (let i = 0; i < 10000; i++) {
    const d = e.nextDouble();
    assert.ok(d >= 0 && d < 1);
  }
});

test("bounded range", () => {
  const e = new Engine(99n);
  assert.equal(e.bounded(0n), 0n);
  for (let i = 0; i < 10000; i++) assert.ok(e.bounded(7n) < 7n);
});

test("discard equivalence", () => {
  const a = new Engine(555n);
  const b = new Engine(555n);
  a.discard(50);
  for (let i = 0; i < 50; i++) b.nextU64();
  for (let i = 0; i < 100; i++) assert.equal(a.nextU64(), b.nextU64());
});
