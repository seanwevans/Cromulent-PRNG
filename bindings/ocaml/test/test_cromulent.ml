(* Self-contained test for the OCaml Cromulent port. Verifies bit-for-bit
   parity with the C reference vectors and basic range/discard behavior. *)

let engine_ref =
  [| 0x8b0849848b39737dL; 0x829ecfb661e3a84dL; 0x6cfb2afb89b5dc83L;
     0x8ad5c0d490669f95L; 0x8d4459e6318f2474L; 0xa0b907b845990f61L;
     0x2143675f2f4ff1ecL; 0x38fff6f9c33c4f8fL |]

let strong_ref =
  [| 0xa1e9fb73cc5c77faL; 0xd8bc61a96accc72eL; 0x3f98dad0bcb1c8f3L;
     0xb179513c44fe1f0aL; 0x413b884be5b9955fL; 0x4b682d94916239a1L;
     0xe7b93a4600d77791L; 0x6a54f95b111a3555L |]

let failures = ref 0

let check cond msg =
  if not cond then begin
    Printf.eprintf "FAIL: %s\n" msg;
    incr failures
  end

let () =
  print_endline "Running Cromulent OCaml engine tests";

  print_string "Testing engine matches C reference... ";
  let e = Cromulent.make_engine ~seed:0x0123456789ABCDEFL () in
  Array.iteri
    (fun i want -> check (Int64.equal (Cromulent.next e) want)
        (Printf.sprintf "engine output %d" i))
    engine_ref;
  print_endline "OK";

  print_string "Testing strong engine matches C reference... ";
  let s = Cromulent.make_strong_engine ~seed:0x0123456789ABCDEFL () in
  Array.iteri
    (fun i want -> check (Int64.equal (Cromulent.strong_next s) want)
        (Printf.sprintf "strong output %d" i))
    strong_ref;
  print_endline "OK";

  print_string "Testing next_double range... ";
  let d = Cromulent.make_engine ~seed:42L () in
  check (Float.abs (Cromulent.next_double d -. 0.42990649088115307) < 1e-15)
    "first double";
  for _ = 1 to 10000 do
    let v = Cromulent.next_double d in
    check (v >= 0.0 && v < 1.0) "double in range"
  done;
  print_endline "OK";

  print_string "Testing bounded range... ";
  let b = Cromulent.make_engine ~seed:99L () in
  check (Int64.equal (Cromulent.bounded b 0L) 0L) "bounded 0";
  for _ = 1 to 10000 do
    check (Int64.unsigned_compare (Cromulent.bounded b 7L) 7L < 0) "bounded < 7"
  done;
  print_endline "OK";

  print_string "Testing discard equivalence... ";
  let a1 = Cromulent.make_engine ~seed:555L () in
  let a2 = Cromulent.make_engine ~seed:555L () in
  Cromulent.discard a1 50;
  for _ = 1 to 50 do ignore (Cromulent.next a2) done;
  check (Int64.equal (Cromulent.next a1) (Cromulent.next a2)) "discard equivalence";
  print_endline "OK";

  if !failures = 0 then begin
    print_endline "All OCaml engine tests passed successfully!";
    exit 0
  end else begin
    Printf.printf "%d check(s) failed!\n" !failures;
    exit 1
  end
