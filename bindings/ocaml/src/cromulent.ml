(* The Cromulent PRNG -- an OCaml port of the scalar reference generator.

   [make_engine] / [next] reproduce the identical 64-bit stream as the C
   reference implementation (cromulent_init / cromulent_next) for any given
   seed; [make_strong_engine] / [strong_next] mirror the heavier
   cromulent_strong variant.

   OCaml's [int64] is signed, but the [Int64] operations act on the two's
   complement bit pattern and wrap like the unsigned C generator. Values that
   must be interpreted as unsigned use [Int64.unsigned_compare] and
   [Int64.unsigned_rem]. *)

let c1 = 0x9e3779b97f4a7c15L
let c2 = 0xbf58476d1ce4e5b9L
let c3 = 0x94d049bb133111ebL
let c6 = 0xd1342543de82ef95L
let mh3 = 0xd6e8feb86659fd93L

(* Default seed, shared with the C library. *)
let default_seed = 0x853c49e6748fea9bL

let ( +% ) = Int64.add
let ( *% ) = Int64.mul
let ( ^% ) = Int64.logxor
let ( &% ) = Int64.logand
let srl = Int64.shift_right_logical
let sll = Int64.shift_left

let rotl x k = Int64.logor (sll x k) (srl x (64 - k))

let mix_fast x =
  let x = x ^% srl x 32 in
  let x = x *% mh3 in
  x ^% srl x 32

(* SplitMix64-style seed expansion, matching cromulent_init. *)
let seed_expand seed =
  let z = ref seed in
  let step () =
    z := !z +% c1;
    z := (!z ^% srl !z 30) *% c2;
    z := (!z ^% srl !z 27) *% c3;
    !z ^% srl !z 31
  in
  let v0 = step () in
  let v1 = step () in
  (v0, v1)

(* High 64 bits of the unsigned 128-bit product a*b (32-bit limbs). *)
let umul_high a b =
  let mask = 0xffffffffL in
  let a_lo = a &% mask and a_hi = srl a 32 in
  let b_lo = b &% mask and b_hi = srl b 32 in
  let lolo = a_lo *% b_lo in
  let hilo = a_hi *% b_lo in
  let lohi = a_lo *% b_hi in
  let hihi = a_hi *% b_hi in
  let carry = srl (srl lolo 32 +% (hilo &% mask) +% (lohi &% mask)) 32 in
  hihi +% srl hilo 32 +% srl lohi 32 +% carry

type engine = { mutable s0 : int64; mutable s1 : int64 }

let make_engine ?(seed = default_seed) () =
  let s0, s1 = seed_expand seed in
  { s0; s1 }

(* Advance the state and return the next 64-bit output. *)
let next e =
  let s0 = e.s0 and s1 = e.s1 in
  e.s0 <- (s0 *% c6) +% s1;
  e.s1 <- rotl s1 31 +% mix_fast s0;
  let r = s0 +% rotl s1 11 in
  let r = r ^% srl r 27 in
  let r = r *% c3 in
  r ^% srl r 27

(* Uniform float in [0, 1) using the top 53 bits. *)
let next_double e =
  Int64.to_float (srl (next e) 11) *. (1.0 /. 9007199254740992.)

(* Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n = 0. *)
let bounded e n =
  if Int64.equal n 0L then 0L
  else begin
    let x = ref (next e) in
    let low = ref (!x *% n) in
    let hi = ref (umul_high !x n) in
    if Int64.unsigned_compare !low n < 0 then begin
      let threshold = Int64.unsigned_rem (Int64.neg n) n in
      while Int64.unsigned_compare !low threshold < 0 do
        x := next e;
        low := !x *% n;
        hi := umul_high !x n
      done
    end;
    !hi
  end

(* Advance the stream by z steps, discarding the output. *)
let discard e z =
  for _ = 1 to z do
    ignore (next e)
  done

type strong_engine = { mutable a : int64; mutable b : int64 }

let make_strong_engine ?(seed = default_seed) () =
  let a, b = seed_expand seed in
  { a; b }

let strong_next e =
  let a = e.a and b = e.b in
  let b = b +% rotl a 13 in
  let a = (rotl a 29 *% c1) +% b in
  let b = rotl b 17 ^% a in
  let a = a +% rotl (b *% c2) 31 in
  let b = b +% rotl a 23 in
  let a = rotl (a ^% b) 52 in
  let output = a +% rotl b 41 in
  e.a <- a +% c1;
  e.b <- b ^% srl a 17;
  mix_fast output

let strong_discard e z =
  for _ = 1 to z do
    ignore (strong_next e)
  done
