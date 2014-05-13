#lang racket/base

;                      /\ \__                /\ \
;  _ __    __      ____\ \ ,_\    __      ___\ \ \___      __
; /\`'__\/'__`\   /',__\\ \ \/  /'__`\   /'___\ \  _ `\  /'__`\
; \ \ \//\ \L\.\_/\__, `\\ \ \_/\ \L\.\_/\ \__/\ \ \ \ \/\  __/
;  \ \_\\ \__/.\_\/\____/ \ \__\ \__/.\_\ \____\\ \_\ \_\ \____\
;   \/_/ \/__/\/_/\/___/   \/__/\/__/\/_/\/____/ \/_/\/_/\/____/
; Mustache template engine for Racket

; Inverted Section tags and End Section tags are used in combination
; to wrap a section of the template.
;
; These tags' content MUST be a non-whitespace character sequence NOT
; containing the current closing delimiter; each Inverted Section tag
; MUST be followed by an End Section tag with the same content within
; the same section.
;
; This tag's content names the data to replace the tag. Name
; resolution is as follows:
;
; 1) Split the name on periods; the first part is the name to resolve,
; any remaining parts should be retained.
;
; 2) Walk the context stack from top to bottom, finding the first
; context that is a) a hash containing the name as a key OR b) an
; object responding to a method with the given name.
;
; 3) If the context is a hash, the data is the value associated with
; the name.
;
; 4) If the context is an object and the method with the given name
; has an arity of 1, the method SHOULD be called with a String
; containing the unprocessed contents of the sections; the data is the
; value returned.
;
; 5) Otherwise, the data is the value returned by calling the method
; with the given name.
;
; 6) If any name parts were retained in step 1, each should be
; resolved against a context stack containing only the result from the
; former resolution. If any part fails resolution, the result should
; be considered falsey, and should interpolate as the empty string.
;
; If the data is not of a list type, it is coerced into a list as
; follows: if the data is truthy (e.g. `!!data == true`), use a
; single-element list containing the data, otherwise use an empty
; list.
;
; This section MUST NOT be rendered unless the data list is empty.
;
; Inverted Section and End Section tags SHOULD be treated as
; standalone when appropriate.

(require rackunit
         rackunit/text-ui
         "rastache-test-case.rkt")

(define inverted-tests
  (test-suite
   "Inverted tests"

   (rast-t-case "Falsey"
                #hash{( boolean . #f )}
                "\"{{^boolean}}This should be rendered.{{/boolean}}\""
                "\"This should be rendered.\""
                "Falsey sections should have their contents rendered.")

   (rast-t-case "Truthy"
                #hash{( boolean . #t )}
                "\"{{^boolean}}This should not be rendered.{{/boolean}}\""
                "\"\""
                "Truthy sections should have their contents omitted.")

   (rast-t-case "Context"
                #hash{( context . #hash{( name . "Joe" )} )}
                "\"{{^context}}Hi {{name}}.{{/context}}\""
                "\"\""
                "Objects and hashes should behave like truthy values.")

   (rast-t-case "List"
                #hash{( data . #hash{( list . '(#hash{( n . 1 )}
                                                #hash{( n . 2 )}
                                                #hash{( n . 3 )}) )} )}
                "\"{{^list}}{{n}}{{/list}}\""
                "\"\""
                "Lists should behave like truthy values.")

   (rast-t-case "Empty List"
                #hash{( list . '() )}
                "\"{{^list}}Yay lists!{{/list}}\""
                "\"Yay lists!\""
                "Empty lists should behave like falsey values.")

   (rast-t-case "Doubled"
                #hash{( bool . #f )( two . "second" )}
                "{{^bool}}
                 * first
                 {{/bool}}
                 * {{two}}
                 {{^bool}}
                 * third
                 {{/bool}}"
                "* first
                 * second
                 * third"
                "Multiple inverted sections per template should be permitted.")

   (rast-t-case "Nested (Falsey)"
                #hash{( bool . #f )}
                "| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |"
                "| A B C D E |"
                "Nested falsey sections should have their contents rendered.")

   (rast-t-case "Nested (Truthy)"
                #hash{( bool . #t )}
                "| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |"
                "| A E |"
                "Nested truthy sections should be omitted.")

   (rast-t-case "Context Misses"
                #hash()
                "[{{^missing}}Cannot find key 'missing'!{{/missing}}]"
                "[Cannot find key 'missing'!]"
                "Failed context lookups should be considered falsey.")

   ;; Dotted Names
   (rast-t-case "Dotted Names - Truthy"
                #hash{( a . #hash{( b . #hash{( c . #t )} )} )}
                "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"\""
                "\"\" == \"\""
                "Dotted names should be valid for Inverted Section tags.")

   (rast-t-case "Dotted Names - Falsey"
                #hash{( a . #hash{( b . #hash{( c . #f )} )} )}
                "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\""
                "\"Not Here\" == \"Not Here\""
                "Dotted names that cannot be resolved should be considered falsey.")

   (rast-t-case "Dotted Names - Broken Chains"
                #hash{( a . #hash() )}
                "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\""
                "\"Not Here\" == \"Not Here\""
                "Dotted names that cannot be resolved should be considered falsey.")

   ;; Whitespace Sensitivity
   (rast-t-case "Surrounding Whitespace"
                #hash{( boolean . #f )}
                " | {{^boolean}}\t|\t{{/boolean}} | \n"
                " | \t|\t | \n"
                "Inverted sections should not alter surrounding whitespace.")

   (rast-t-case "Internal Whitespace"
                #hash{( boolean . #f )}
                " | {{^boolean}} {{! Important Whitespace }}\n {{/boolean}} | \n"
                " |  \n  | \n"
                "Inverted should not alter internal whitespace.")

   (rast-t-case "Indented Inline Sections"
                #hash{( boolean . #f )}
                " {{^boolean}}NO{{/boolean}}\n {{^boolean}}WAY{{/boolean}}\n"
                " NO\n WAY\n"
                "Single-line sections should not alter surrounding whitespace.")

   (rast-t-case "Standalone Lines"
                #hash{( boolean . #f )}
                "| This Is
                 {{^boolean}}
                 |
                 {{/boolean}}
                 | A Line"
                "| This Is
                 |
                 | A Line"
                "Standalone lines should be removed from the template.")

   (rast-t-case "Standalone Indented Lines"
                #hash{( boolean . #f )}
                "| This Is
                   {{^boolean}}
                 |
                   {{/boolean}}
                 | A Line"
                "| This Is
                 |
                 | A Line"
                "Standalone indented lines should be removed from the template.")

   (rast-t-case "Standalone Line Endings"
                #hash{( boolean . #f )}
                "|\r\n{{^boolean}}\r\n{{/boolean}}\r\n|"
                "|\r\n|"
                "'\r\n' should be considered a newline for standalone tags.")

   (rast-t-case "Standalone Without Previous Line"
                #hash{( boolean . #f )}
                "  {{^boolean}}\n^{{/boolean}}\n/"
                "^\n/"
                "Standalone tags should not require a newline to precede them.")

   (rast-t-case "Standalone Without Newline"
                #hash{( boolean . #f )}
                "^{{^boolean}}\n/\n  {{/boolean}}"
                "^\n/\n"
                "Standalone tags should not require a newline to follow them.")

   ;; Whitespace Insensitivity
   (rast-t-case "Padding"
                #hash{( boolean . #f )}
                "|{{^ boolean }}={{/ boolean }}|"
                "|=|"
                "Superfluous in-tag whitespace should be ignored.")))

(run-tests inverted-tests)