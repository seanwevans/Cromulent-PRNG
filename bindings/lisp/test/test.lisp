;;;; Self-contained test for the Common Lisp Cromulent port. Verifies
;;;; bit-for-bit parity with the C reference vectors and basic range/discard
;;;; behavior. Run with: sbcl --script test/test.lisp  (from bindings/lisp)

(load "src/cromulent.lisp")

(in-package :cromulent)

(defparameter *engine-ref*
  #(#x8b0849848b39737d #x829ecfb661e3a84d #x6cfb2afb89b5dc83
    #x8ad5c0d490669f95 #x8d4459e6318f2474 #xa0b907b845990f61
    #x2143675f2f4ff1ec #x38fff6f9c33c4f8f))

(defparameter *strong-ref*
  #(#xa1e9fb73cc5c77fa #xd8bc61a96accc72e #x3f98dad0bcb1c8f3
    #xb179513c44fe1f0a #x413b884be5b9955f #x4b682d94916239a1
    #xe7b93a4600d77791 #x6a54f95b111a3555))

(defparameter *failures* 0)

(defun check (cond msg)
  (unless cond
    (format *error-output* "FAIL: ~a~%" msg)
    (incf *failures*)))

(format t "Running Cromulent Common Lisp engine tests~%")

(format t "Testing engine matches C reference... ")
(let ((e (make-engine #x0123456789ABCDEF)))
  (dotimes (i (length *engine-ref*))
    (check (= (engine-next e) (aref *engine-ref* i))
           (format nil "engine output ~d" i))))
(format t "OK~%")

(format t "Testing strong engine matches C reference... ")
(let ((s (make-strong #x0123456789ABCDEF)))
  (dotimes (i (length *strong-ref*))
    (check (= (strong-next s) (aref *strong-ref* i))
           (format nil "strong output ~d" i))))
(format t "OK~%")

(format t "Testing next-double range... ")
(let ((d (make-engine 42)))
  (check (< (abs (- (engine-next-double d) 0.42990649088115307d0)) 1d-15)
         "first double")
  (dotimes (i 10000)
    (let ((v (engine-next-double d)))
      (check (and (>= v 0d0) (< v 1d0)) "double in range"))))
(format t "OK~%")

(format t "Testing bounded range... ")
(let ((b (make-engine 99)))
  (check (= (engine-bounded b 0) 0) "bounded 0")
  (dotimes (i 10000)
    (check (< (engine-bounded b 7) 7) "bounded < 7")))
(format t "OK~%")

(format t "Testing discard equivalence... ")
(let ((a1 (make-engine 555))
      (a2 (make-engine 555)))
  (engine-discard a1 50)
  (dotimes (i 50) (engine-next a2))
  (check (= (engine-next a1) (engine-next a2)) "discard equivalence"))
(format t "OK~%")

(if (zerop *failures*)
    (progn (format t "All Common Lisp engine tests passed successfully!~%")
           (sb-ext:exit :code 0))
    (progn (format t "~d check(s) failed!~%" *failures*)
           (sb-ext:exit :code 1)))
