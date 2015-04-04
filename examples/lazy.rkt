#lang racket/base

(require rastache)

(define template
#<<HERESTRING
Hello {{name}}
You have just won ${{value}}!
{{#in_ca}}
Well, ${{ taxed_value }}, after taxes.
{{/in_ca}}
Love, {{owner}}
HERESTRING
)

(rast-compile/render (open-input-string template)
                     (lambda (x) x)
                     (current-output-port))
