;;;; The Cromulent PRNG -- a Common Lisp port of the scalar reference generator.
;;;;
;;;; MAKE-ENGINE / ENGINE-NEXT reproduce the identical 64-bit stream as the C
;;;; reference implementation (cromulent_init / cromulent_next) for any given
;;;; seed; MAKE-STRONG / STRONG-NEXT mirror the heavier cromulent_strong
;;;; variant.
;;;;
;;;; Common Lisp integers are arbitrary precision, so every operation is masked
;;;; back to 64 bits with +MASK+ to reproduce the wrapping arithmetic of the C
;;;; generator.

(defpackage :cromulent
  (:use :cl)
  (:export :make-engine :engine-next :engine-next-double :engine-bounded
           :engine-discard :engine-s0 :engine-s1
           :make-strong :strong-next :strong-discard :strong-a :strong-b
           :+default-seed+))

(in-package :cromulent)

(defconstant +mask+ #xFFFFFFFFFFFFFFFF)
(defconstant +c1+ #x9e3779b97f4a7c15)
(defconstant +c2+ #xbf58476d1ce4e5b9)
(defconstant +c3+ #x94d049bb133111eb)
(defconstant +c6+ #xd1342543de82ef95)
(defconstant +mh3+ #xd6e8feb86659fd93)

;;; Default seed, shared with the C library.
(defconstant +default-seed+ #x853c49e6748fea9b)

(declaim (inline mask u+ u* rotl mix-fast))

(defun mask (x) (logand x +mask+))
(defun u+ (a b) (mask (+ a b)))
(defun u* (a b) (mask (* a b)))

(defun rotl (x k)
  (mask (logior (ash x k) (ash x (- k 64)))))

(defun mix-fast (x)
  (let ((x (logxor x (ash x -32))))
    (setf x (u* x +mh3+))
    (logxor x (ash x -32))))

;;; SplitMix64-style seed expansion, matching cromulent_init.
(defun seed-expand (seed)
  (let ((z (mask seed)) v0 v1)
    (flet ((sm-step ()
             (setf z (u+ z +c1+))
             (setf z (u* (logxor z (ash z -30)) +c2+))
             (setf z (u* (logxor z (ash z -27)) +c3+))
             (logxor z (ash z -31))))
      (setf v0 (sm-step))
      (setf v1 (sm-step))
      (values v0 v1))))

(defstruct (engine (:constructor %make-engine))
  (s0 0 :type (unsigned-byte 64))
  (s1 0 :type (unsigned-byte 64)))

(defun make-engine (&optional (seed +default-seed+))
  (multiple-value-bind (s0 s1) (seed-expand seed)
    (%make-engine :s0 s0 :s1 s1)))

;;; Advance the state and return the next 64-bit output.
(defun engine-next (e)
  (let ((s0 (engine-s0 e))
        (s1 (engine-s1 e)))
    (setf (engine-s0 e) (u+ (u* s0 +c6+) s1))
    (setf (engine-s1 e) (u+ (rotl s1 31) (mix-fast s0)))
    (let* ((r (u+ s0 (rotl s1 11)))
           (r (logxor r (ash r -27)))
           (r (u* r +c3+))
           (r (logxor r (ash r -27))))
      r)))

;;; Uniform double-float in [0, 1) using the top 53 bits.
(defun engine-next-double (e)
  (/ (ash (engine-next e) -11) 9007199254740992d0))

;;; Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n = 0.
(defun engine-bounded (e n)
  (if (zerop n)
      0
      (let* ((x (engine-next e))
             (m (* x n))
             (low (logand m +mask+))
             (hi (ash m -64)))
        (when (< low n)
          (let ((threshold (mod (- (expt 2 64) n) n)))
            (loop while (< low threshold) do
              (setf x (engine-next e)
                    m (* x n)
                    low (logand m +mask+)
                    hi (ash m -64)))))
        hi)))

;;; Advance the stream by z steps, discarding the output.
(defun engine-discard (e z)
  (dotimes (i z) (engine-next e)))

(defstruct (strong (:constructor %make-strong))
  (a 0 :type (unsigned-byte 64))
  (b 0 :type (unsigned-byte 64)))

(defun make-strong (&optional (seed +default-seed+))
  (multiple-value-bind (a b) (seed-expand seed)
    (%make-strong :a a :b b)))

(defun strong-next (e)
  (let ((a (strong-a e))
        (b (strong-b e)))
    (setf b (u+ b (rotl a 13)))
    (setf a (u+ (u* (rotl a 29) +c1+) b))
    (setf b (logxor (rotl b 17) a))
    (setf a (u+ a (rotl (u* b +c2+) 31)))
    (setf b (u+ b (rotl a 23)))
    (setf a (rotl (logxor a b) 52))
    (let ((output (u+ a (rotl b 41))))
      (setf (strong-a e) (u+ a +c1+))
      (setf (strong-b e) (logxor b (ash a -17)))
      (mix-fast output))))

(defun strong-discard (e z)
  (dotimes (i z) (strong-next e)))
