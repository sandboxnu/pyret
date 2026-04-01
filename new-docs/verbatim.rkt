#lang racket

(require "pollenboots/utils.rkt")

(provide (all-defined-out))

(define (pyret #:style [style #f] . elems)
  `(tt ([class "pyret-highlight"]) ,@elems))

(define (pyret-id item [mod #f])
  (ref-gloss item (pyret item) #:mod mod))

(define (tt . elems)
  `(tt () ,@elems))

(define (save-example-to-file strs file)
  (call-with-output-file file
    (lambda (o)
      (fprintf o "# example in ~s, saved to ~s\n" (calc-here-path-from-project-root) file)
      (for ([str strs])
        (display str o)))
    #:exists 'replace))

(define get-examples-count (make-counter))

(define (examples #:show-try-it [show-try-it #t] . elems)
  (if show-try-it
      (let ()
        (define file (format ".examples-~a.arr" (get-examples-count)))
        (save-example-to-file elems file)
        `(div ()
              (p () (b () "Examples:"))
              (pre ([class "pyret-highlight"]) ,@elems)
              (a ([class "show-embed"]
                  [code ,(string-join elems " ")])
                 "(Try it!)")))
      (let ()
        (define elem-string (apply string-append elems))
        (printf "WARNING: examples ~s missing try-it in ~a\n" elem-string (calc-here-path-from-project-root))
        `(div ()
              (p () (b () "Examples:"))
              (pre ([class "pyret-highlight"]) ,@elems)))))

(define (verbatim #:style [style "nothing_special"] #:show-try-it [show-try-it #f] . elems)
  ; (printf "@@@ doing verbatim ~s\n" elems)
  (define attribs `([class ,style]))
  `(pre ,attribs ,@elems))

(define codedisp verbatim)

(define (pyret-block #:style [style #f] #:show-try-it [show-try-it #f] . elems)
  (define classes (string-append (if style (string-append style " ") "") "pyret-highlight"))
  `(pre ([class ,classes]) ,@elems))

(define (data-spec name . elems)
  ; (printf "### data-spec ~s ~s \n" name elems)
  `(div ()
        ,(make-gloss name)
        ,@elems))

(define (variants . elems)
  ; (printf "### variants ~s\n" elems)
  `(div ()
        ,@elems))

(define (shared . elems)
  `(div ()
        (div ([class "nested"]) "Shared Methods")
        ,@elems))

(define (constr-spec name . elems)
  `(div ()
        (pre () ,name)
        ,@elems))

(define (members . elems)
  `(div ()
        (div ([class "nested"]) "Fields")
        ,@elems))

(define (with-members . elems)
  `(div ()
        (div ([class "nested"]) "Methods")
        ,@elems))

(define (method-spec #:params [params #f] #:contract [contract #f] #:return [return #f]
                     #:doc [doc #f]
                     #:args [args #f] #:alt-docstrings [alt-docstrings #f]
                     #:examples [examples '()] name . elems)
  ; (printf "### method-spec ~s ~s ~s\n" contract name elems)
  (define mname (string-append "." name))
  `(div ([class "nested"])
        (tt ([class "pyret-display"])
            ,(if contract `(span () ,mname " :: " ,contract)
                 mname))
        ,(if doc `(div () ,doc) "")
        ,@elems))

(define (member-spec #:type [type #f] #:contract [contract #f] fname . elems)
  ; (printf "*** member-spec fname= ~s contract= ~s elems= ~s\n" fname contract elems)
  `(div ([class "nested"])
        (tt ()
            ,(if contract
                 `(span () ,fname " :: " ,contract)
                 fname))
        ,@elems))

; (define (data-spec name type-vars variants shared)
;   ; (printf "### data-spec ~s ~s ~s \n" name type-varss variants  shared )
;   `(pre () (tt () ,(format "~a~a:"
;                     name
;                     (if deps (format "<~a>" (add-between deps ", ")) "")))
;           "\n"
;           (div ()
;                 ,@(add-between
;                     (map
;                       (lambda (clause)
;                         `(tt () "   | " ,clause))
;                       clauses) "\n"))
;           (tt () "end")))

(define (data-spec2 #:no-toc [no-toc #f] name deps clauses)
  ; (printf "### doing data-spec2 ~s deps=~s ~s\n" name deps clauses)
  `(pre ([class "pyret-display"])
        ,(make-gloss name)
        (span ()
              "data " ,(ref-gloss name)
              ,@(if (and deps (cons? deps))
                    (append (list "<") (add-between deps ", ")  (list ">"))
                    '()))
          "\n"
         (div ()
                ,@(add-between
                    (map
                      (lambda (clause)
                        `(tt () "   | " ,clause))
                      clauses) "\n"))
          (tt () "end")))

(define (singleton-spec2 cname name)
  `(span () ,(ref-gloss name)))

(define (constructor-spec cname name [args #f])
  ; (printf "### constructor-spec cname= ~s name= ~s args= ~s\n" cname name args)
  (let ([x
          (if (not args)
              `(span () ,(ref-gloss name))
              `(span () ,(ref-gloss name)
                     "(" ,@(add-between
                             (map (lambda (arg)
                                    (define fname (first arg))
                                    (define contract (second (third arg)))
                                    ; (printf "fname= ~s contract= ~s\n" fname contract)
                                    `(span () ,fname " :: " ,contract))
                                  args)
                             ", ")
                     ")"))])
    ; (printf "### x= ~s\n" x)
    x))

(define (function #:contract [contract #f] #:args [args #f]
                  #:return [return "return"]
                  #:examples [examples "examples"]
                  #:alt-docstrings [alt-docstrings "alt-docstrings"]
                  name . elems)
  ; (printf "function ~a args are ~s, contract = ~s\n" name args contract)
  `(div ()
        ,(make-gloss name)
        (pre ([class "pyret-display"])
             ,(ref-gloss name) " :: "
             ,(if (and args (not contract))
                  `(span ()
                        "(" ,@(add-between
                                (map (lambda (arg)
                                       (let ([arg (first arg)]
                                             [type (second arg)])
                                         ; (printf "arg/type are ~s, ~s\n" arg type)
                                         (cond [type
                                                 `(span () ,arg " :: " ,type)]
                                               [(list? contract)
                                                ; (printf "contract = ~s\n" contract)
                                                (let ([n (length contract)])
                                                  (let ([res
                                                          (if (>= n 3)
                                                              `(span () ,arg " :: "
                                                                     ,(third contract))
                                                              `(span () "() -> "
                                                                     ,(second contract)))])
                                                    ; (printf "done V\n")
                                                    res
                                                    ))]
                                               [else
                                                 arg])))
                                     args) ", ")
                        ")"
                        )
                  ; contract
                  (or contract "unspecified_contract")
                  ))
        ,@elems))
