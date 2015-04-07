#lang racket/base

(require rastache)

(define template
#<<HERESTRING
Hello {{name}}
You have just won ${{value}}!
Love, {{owner}}
HERESTRING
)

(rast-compile/render (open-input-string template)
                     ;(make-hash (list (cons 'name (lambda () 's))))
                     (lambda (x) (string-append (symbol->string x) "-parameter"))
                     (current-output-port))
