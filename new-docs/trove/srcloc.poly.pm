#lang pollen


◊docmodule["srcloc"]{
  ◊; Ignored type testers
  ◊ignore[(list "is-builtin" "is-srcloc")]
  ◊section[#:tag "srcloc_DataTypes"]{Data types}
  ◊data-spec["Srcloc"]{
    ◊variants{
      ◊constr-spec["builtin"]{
        ◊members{◊member-spec["module-name" #:contract A]}
        ◊with-members{
          ◊method-spec[
            "format" #:contract (a-ftype (a-var-type "show-file" A) A)
            ;; N.B. Pyret contract: (Srcloc, Any -> Any)
            
          ]
          ◊method-spec[
            "same-file" #:contract (a-ftype (a-var-type "other" A) A)
            ;; N.B. Pyret contract: (Srcloc, Any -> Any)
            
          ]
          ◊method-spec[
            "before" #:contract (a-ftype (a-var-type "other" A) A)

            ;; N.B. Pyret contract: (Srcloc, Any -> Any)
            
          ]
        }
      }
      ◊constr-spec["srcloc"]{
        ◊members{
          ◊member-spec["source" #:contract S]
          ◊member-spec["start-line" #:contract N]
          ◊member-spec["start-column" #:contract N]
          ◊member-spec["start-char" #:contract N]
          ◊member-spec["end-line" #:contract N]
          ◊member-spec["end-column" #:contract N]
          ◊member-spec["end-char" #:contract N]
        }
        ◊with-members{
          ◊method-spec[
            "format" #:contract (a-ftype (a-var-type "show-file" A) A)

            ;; N.B. Pyret contract: (Srcloc, Any -> Any)
            #:doc "Returns either 'file: line, col' or just 'line, col', depending on the show-file flag"
            
          ]
          ◊method-spec[
            "same-file" #:contract (a-ftype (a-var-type "other" SL) A)

            ;; N.B. Pyret contract: (Srcloc, Srcloc60 -> Any)
            
          ]
          ◊method-spec[
            "before" #:contract (a-ftype (a-var-type "other" SL) A)

            ;; N.B. Pyret contract: (Srcloc, Srcloc60 -> Any)
            
          ]
        }
      }
    }
    ◊shared{
      ◊method-spec[
        "after" #:contract (a-ftype (a-var-type "other" A) A)

        ;; N.B. Pyret contract: (Srcloc, Any -> Any)
        
      ]
    }
  }
  
  ◊section[#:tag "srcloc_Functions"]{Functions}
}
