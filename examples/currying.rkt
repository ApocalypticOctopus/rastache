#lang racket

(require rastache)
(require (planet williams/describe:1:5/describe))

(define template "t1={{t1}}
t2={{t2}}
t3={{t3.y.h}}
t4={{t4.b}}
t5={{t5.a.b}}
t6.a.b={{t6.a.b}}
t7.r.g.t.d.s={{t7.r.g.t.d.s}}")

;Expected output:
;t1=tset
;t2=test2
;t3=&h;
;t4=&b;
;t5=&b;
;t6.a.b=ab
;t7.r.g.t.d.s=rgtds

(define test1 "tset")
(define (test2) "test2")
(define (test3 x) test4)
(define (test4 x) x)
(define (test5 x) (lambda (y) y))
(define (test6 x y) (string-append (symbol->string x) (symbol->string y)))
(define (test7 x y . rest)
  (string-append (symbol->string x) (symbol->string y)
                 (apply string-append
                        (map symbol->string rest))))

(rast-compile/render (open-input-string template)
                     `#hash((t1 . ,test1)
                            (t2 . ,test2)
                            (t3 . ,test3)
                            (t4 . ,test4)
                            (t5 . ,test5)
                            (t6 . ,test6)
                            (t7 . ,test7))
                            
                     
                     (current-output-port))
