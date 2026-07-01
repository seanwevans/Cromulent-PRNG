module Cromulent.Test

open Cromulent

let engineRef =
    [| 0x8b0849848b39737dUL; 0x829ecfb661e3a84dUL; 0x6cfb2afb89b5dc83UL
       0x8ad5c0d490669f95UL; 0x8d4459e6318f2474UL; 0xa0b907b845990f61UL
       0x2143675f2f4ff1ecUL; 0x38fff6f9c33c4f8fUL |]

let strongRef =
    [| 0xa1e9fb73cc5c77faUL; 0xd8bc61a96accc72eUL; 0x3f98dad0bcb1c8f3UL
       0xb179513c44fe1f0aUL; 0x413b884be5b9955fUL; 0x4b682d94916239a1UL
       0xe7b93a4600d77791UL; 0x6a54f95b111a3555UL |]

let mutable failures = 0

let check (cond: bool) (msg: string) =
    if not cond then
        eprintfn "FAIL: %s" msg
        failures <- failures + 1

[<EntryPoint>]
let main _ =
    printfn "Running Cromulent F# engine tests"

    printf "Testing engine matches C reference... "
    let e = CromulentEngine(0x0123456789ABCDEFUL)
    for i in 0 .. engineRef.Length - 1 do
        check (e.NextUInt64() = engineRef.[i]) (sprintf "engine output %d" i)
    printfn "OK"

    printf "Testing strong engine matches C reference... "
    let s = StrongEngine(0x0123456789ABCDEFUL)
    for i in 0 .. strongRef.Length - 1 do
        check (s.NextUInt64() = strongRef.[i]) (sprintf "strong output %d" i)
    printfn "OK"

    printf "Testing NextDouble range... "
    let d = CromulentEngine(42UL)
    check (abs (d.NextDouble() - 0.42990649088115307) < 1e-15) "first double"
    for _ in 1 .. 10000 do
        let v = d.NextDouble()
        check (v >= 0.0 && v < 1.0) "double in range"
    printfn "OK"

    printf "Testing Bounded... "
    let b = CromulentEngine(99UL)
    check (b.Bounded(0UL) = 0UL) "Bounded(0)"
    for _ in 1 .. 10000 do
        check (b.Bounded(7UL) < 7UL) "Bounded(7) < 7"
    printfn "OK"

    printf "Testing Discard equivalence... "
    let a1 = CromulentEngine(555UL)
    let a2 = CromulentEngine(555UL)
    a1.Discard(50UL)
    for _ in 1 .. 50 do a2.NextUInt64() |> ignore
    check (a1.State = a2.State) "Discard(n) == n calls"
    printfn "OK"

    if failures = 0 then
        printfn "All F# engine tests passed successfully!"
        0
    else
        printfn "%d check(s) failed!" failures
        1
