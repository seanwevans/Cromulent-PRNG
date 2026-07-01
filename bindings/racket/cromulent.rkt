#lang racket/base

;; The Cromulent PRNG — a Racket port of the scalar reference generator.
;;
;; `make-engine` / `engine-next!` produce the identical 64-bit stream as the C
;; reference implementation (cromulent_init / cromulent_next) for any given
;; seed. `make-strong-engine` / `strong-engine-next!` mirror the heavier
;; cromulent_strong variant.
;;
;; Racket integers are arbitrary precision, so every operation is masked back
;; to 64 bits with `mask` to reproduce the wrapping arithmetic of the C
;; generator.

(provide default-seed
         (struct-out engine)
         make-engine
         engine-next!
         engine-next-double!
         engine-next-float!
         engine-bounded!
         engine-discard!
         (struct-out strong-engine)
         make-strong-engine
         strong-engine-next!
         strong-engine-discard!)

(define MASK (- (arithmetic-shift 1 64) 1))

(define C1 #x9e3779b97f4a7c15)
(define C2 #xbf58476d1ce4e5b9)
(define C3 #x94d049bb133111eb)
(define C6 #xd1342543de82ef95)
(define MH3 #xd6e8feb86659fd93)

;; Default seed, shared with the C library.
(define default-seed #x853c49e6748fea9b)

(define (mask x) (bitwise-and x MASK))

;; 64-bit left rotation. `x` is assumed already masked (non-negative).
(define (rotl x k)
  (mask (bitwise-ior (arithmetic-shift x k)
                     (arithmetic-shift x (- k 64)))))

(define (mix-fast x0)
  (let* ([x (bitwise-xor x0 (arithmetic-shift x0 -32))]
         [x (mask (* x MH3))]
         [x (bitwise-xor x (arithmetic-shift x -32))])
    x))

;; SplitMix64-style seed expansion, matching cromulent_init.
;; Returns two 64-bit values.
(define (seed-expand seed)
  (define (step z)
    (let* ([z (mask (+ z C1))]
           [z (mask (* (bitwise-xor z (arithmetic-shift z -30)) C2))]
           [z (mask (* (bitwise-xor z (arithmetic-shift z -27)) C3))])
      (values (bitwise-xor z (arithmetic-shift z -31)) z)))
  (define-values (v0 z1) (step (mask seed)))
  (define-values (v1 _z2) (step z1))
  (values v0 v1))

;; ---------------------------------------------------------------------------
;; Primary engine
;; ---------------------------------------------------------------------------

(struct engine (s0 s1) #:mutable #:transparent)

(define (make-engine [seed default-seed])
  (define-values (s0 s1) (seed-expand seed))
  (engine s0 s1))

;; Advance the state and return the next 64-bit output.
(define (engine-next! e)
  (define s0 (engine-s0 e))
  (define s1 (engine-s1 e))
  (set-engine-s0! e (mask (+ (* s0 C6) s1)))
  (set-engine-s1! e (mask (+ (rotl s1 31) (mix-fast s0))))
  (let* ([r (mask (+ s0 (rotl s1 11)))]
         [r (bitwise-xor r (arithmetic-shift r -27))]
         [r (mask (* r C3))]
         [r (bitwise-xor r (arithmetic-shift r -27))])
    r))

;; Uniform flonum in [0, 1) using the top 53 bits.
(define (engine-next-double! e)
  (* (arithmetic-shift (engine-next! e) -11) (expt 2.0 -53)))

;; Uniform flonum in [0, 1) using the top 24 bits (single precision).
(define (engine-next-float! e)
  (* (arithmetic-shift (engine-next! e) -40) (expt 2.0 -24)))

;; Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n=0.
(define (engine-bounded! e n)
  (cond
    [(= n 0) 0]
    [else
     (let loop ([m (* (engine-next! e) n)])
       (define low (mask m))
       (if (and (< low n) (< low (modulo (mask (- n)) n)))
           (loop (* (engine-next! e) n))
           (arithmetic-shift m -64)))]))

;; Advance the stream by z steps, discarding the output.
(define (engine-discard! e z)
  (for ([_ (in-range z)]) (engine-next! e)))

;; ---------------------------------------------------------------------------
;; Strong engine
;; ---------------------------------------------------------------------------

(struct strong-engine (a b) #:mutable #:transparent)

(define (make-strong-engine [seed default-seed])
  (define-values (a b) (seed-expand seed))
  (strong-engine a b))

(define (strong-engine-next! e)
  (define a0 (strong-engine-a e))
  (define b0 (strong-engine-b e))
  (let* ([b (mask (+ b0 (rotl a0 13)))]
         [a (mask (+ (* (rotl a0 29) C1) b))]
         [b (bitwise-xor (rotl b 17) a)]
         [a (mask (+ a (rotl (mask (* b C2)) 31)))]
         [b (mask (+ b (rotl a 23)))]
         [a (rotl (bitwise-xor a b) 52)]
         [output (mask (+ a (rotl b 41)))])
    (set-strong-engine-a! e (mask (+ a C1)))
    (set-strong-engine-b! e (bitwise-xor b (arithmetic-shift a -17)))
    (mix-fast output)))

(define (strong-engine-discard! e z)
  (for ([_ (in-range z)]) (strong-engine-next! e)))

;; ---------------------------------------------------------------------------
;; Tests
;; ---------------------------------------------------------------------------

(module+ test
  (require rackunit)

  (define engine-ref
    '(#x8b0849848b39737d #x829ecfb661e3a84d #x6cfb2afb89b5dc83
      #x8ad5c0d490669f95 #x8d4459e6318f2474 #xa0b907b845990f61
      #x2143675f2f4ff1ec #x38fff6f9c33c4f8f))

  (define strong-ref
    '(#xa1e9fb73cc5c77fa #xd8bc61a96accc72e #x3f98dad0bcb1c8f3
      #xb179513c44fe1f0a #x413b884be5b9955f #x4b682d94916239a1
      #xe7b93a4600d77791 #x6a54f95b111a3555))

  (test-case "matches C reference"
    (define e (make-engine #x0123456789ABCDEF))
    (for ([want (in-list engine-ref)])
      (check-equal? (engine-next! e) want)))

  (test-case "strong matches C reference"
    (define e (make-strong-engine #x0123456789ABCDEF))
    (for ([want (in-list strong-ref)])
      (check-equal? (strong-engine-next! e) want)))

  (test-case "double in range"
    (define e (make-engine 42))
    (check-= (engine-next-double! e) 0.42990649088115307 1e-15)
    (for ([_ (in-range 10000)])
      (define d (engine-next-double! e))
      (check-true (and (>= d 0.0) (< d 1.0)))))

  (test-case "bounded range"
    (define e (make-engine 99))
    (check-equal? (engine-bounded! e 0) 0)
    (for ([_ (in-range 10000)])
      (check-true (< (engine-bounded! e 7) 7))))

  (test-case "discard equivalence"
    (define a (make-engine 555))
    (define b (make-engine 555))
    (engine-discard! a 50)
    (for ([_ (in-range 50)]) (engine-next! b))
    (check-equal? a b)))
