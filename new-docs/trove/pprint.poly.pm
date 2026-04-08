#lang pollen

◊(define PPD (a-id "PPrintDoc" (xref "pprint" "PPrintDoc")))
◊(define (make-arg name type)
   `(,name ("type" "normal") ("contract" ,type)))


◊(define (ppd-method name #:contract [contract #f])
  (method-doc "PPrintDoc" #f name #:alt-docstrings "" #:contract contract))



  


◊docmodule["pprint"]{
  ◊; Ignored type testers
  ◊ignore[(list "is-mt-doc" "align-spaces")]
  ◊; Unknown: PLEASE DOCUMENT
  ◊ignore[
    (list
      "mt-doc"
      "hardline"
      "lparen"
      "rparen"
      "lbrace"
      "rbrace"
      "lbrack"
      "rbrack"
      "langle"
      "rangle"
      "comma"
      "commabreak")
  ]
  ◊section{The PPrintDoc Datatype}
  This datatype is ◊emph{not} exported directly to users; there are
  ◊seclink[#:tag-prefixes '("pprint_Functions") "Functions"]{easier-to-use
  helper functions} that are exported instead.
  ◊data-spec2["PPrintDoc" '() (list
    ◊constructor-spec["PPrintDoc" "mt-doc" `(,(make-arg "flat-width" N)
                                             ,(make-arg "has-hardline" B))]
    ◊constructor-spec["PPrintDoc" "str" `(,(make-arg "s" S)
                                          ,(make-arg "flat-width" N)
                                          ,(make-arg "has-hardline" B))]
    ◊constructor-spec["PPrintDoc" "hardline" `(,(make-arg "has-hardline" B))]
    ◊constructor-spec["PPrintDoc" "blank" `(,(make-arg "n" N)
                                            ,(make-arg "flat-width" N)
                                            ,(make-arg "has-hardline" B))]
    ◊constructor-spec["PPrintDoc" "concat" `(,(make-arg "fst" PPD)
                                             ,(make-arg "snd" PPD)
                                             ,(make-arg "flat-width" N)
                                             ,(make-arg "has-hardline" B))]
                                          
    ◊constructor-spec["PPrintDoc" "nest" `(,(make-arg "indent" N)
                                           ,(make-arg "d" PPD)
                                           ,(make-arg "flat-width" N)
                                           ,(make-arg "has-hardline" B))]
    ◊constructor-spec["PPrintDoc" "if-flat" `(,(make-arg "flat" PPD)
                                              ,(make-arg "vert" PPD)
                                              ,(make-arg "flat-width" N)
                                              ,(make-arg "has-hardline" B))]
    ◊constructor-spec["PPrintDoc" "align" `(,(make-arg "d" PPD)
                                            ,(make-arg "flat-width" N)
                                            ,(make-arg "has-hardline" B))]
    ◊constructor-spec["PPrintDoc" "align-spaces" `(,(make-arg "n" N)
                                                   ,(make-arg "flat-width" N)
                                                   ,(make-arg "has-hardline" B))]
    ◊constructor-spec["PPrintDoc" "group" `(,(make-arg "D" PPD)
                                            ,(make-arg "flat-width" N)
                                            ,(make-arg "has-hardline" B))]
  )]

  ◊nested[#:style 'inset]{
    Each of the raw constructors for ◊pyret-id{PPrintDoc} contains two
         fields that memoize how wide the document is when printed
         flat, and whether the document contains a hard linebreak.
    ◊constructor-doc["PPrintDoc" "mt-doc" `(,(make-arg "flat-width" N)
                                            ,(make-arg "has-hardline" B))
                     PPD #:private #t]{
    Represents an empty document.
    }
    ◊constructor-doc["PPrintDoc" "str" `(,(make-arg "s" S)
                                         ,(make-arg "flat-width" N)
                                         ,(make-arg "has-hardline" B)) PPD #:private #t]{
    Represents a simple string, that cannot be broken into smaller
    pieces.  Any whitespace in this string is treated as a normal,
    unbreakable character.
    }
    ◊constructor-doc["PPrintDoc" "hardline" `(,(make-arg "has-hardline" B)) PPD #:private #t]{
    Forces a line break: no group containing this document can print
    flat.
    }
    ◊constructor-doc["PPrintDoc" "blank" `(,(make-arg "n" N)
                                           ,(make-arg "flat-width" N)
                                           ,(make-arg "has-hardline" B)) PPD #:private #t]{
    Represents ◊math{n} spaces.  (This is
    simply a memory optimization over storing a ◊pyret{str} of the
    actual whitespace string.)
    }
    ◊constructor-doc["PPrintDoc" "concat" `(,(make-arg "fst" PPD)
                                            ,(make-arg "snd" PPD)
                                            ,(make-arg "flat-width" N)
                                            ,(make-arg "has-hardline" B))
                     PPD #:private #t]{
    Represents printing two documents, one after another.  PPrintDoc both
    documents will be printed in flat mode, or neither will.
    }
    ◊constructor-doc["PPrintDoc" "nest" `(,(make-arg "indent" N)
                                          ,(make-arg "d" PPD)
                                          ,(make-arg "flat-width" N)
                                          ,(make-arg "has-hardline" B)) PPD #:private #t]{
    Adds ◊math{n} spaces to any line breaks that result from printing the
    given document in vertical mode.  This forms an indented paragraph.
    }
    ◊constructor-doc["PPrintDoc" "if-flat" `(,(make-arg "flat" PPD)
                                             ,(make-arg "vert" PPD)
                                             ,(make-arg "flat-width" N)
                                             ,(make-arg "has-hardline" B)) PPD #:private #t]{
    Allows choosing between two documents, depending on whether the document
    is being printed flat or not.  This can be used to implement soft line
    breaks, which turn into whitespace when flat.
    }
    ◊constructor-doc["PPrintDoc" "align" `(,(make-arg "d" PPD)
                                           ,(make-arg "flat-width" N)
                                           ,(make-arg "has-hardline" B)) PPD #:private #t]{
    This aligns its nested content to the current column.  (Unlike
    ◊pyret-id{nest}, which adds or removes indentation relative to the current
    indentation, this aligns to the current position regardless of current
    indentation.) 
    }
    ◊constructor-doc["PPrintDoc" "align-spaces" `(,(make-arg "n" N)
                                                  ,(make-arg "flat-width" N)
                                                  ,(make-arg "has-hardline" B)) PPD #:private #t]{
    In flat mode, this vanishes, but in vertical mode it adds a linebreak and a
    given number of spaces to the next line.
    }
    ◊constructor-doc["PPrintDoc" "group" `(,(make-arg "D" PPD)
                                           ,(make-arg "flat-width" N)
                                           ,(make-arg "has-hardline" B)) PPD #:private #t]{
    This applies ``scoping'' to the current nesting level or flatness mode.  If
    a group can be typeset  in flat mode, it will, regardless of the
    surrounding mode.
    }
  }
  
◊section{PPrintDoc Methods}

These methods are available on all ◊pyret-id{PPrintDoc}s.

◊ppd-method["_plus" #:contract (a-ftype (a-var-type "other" PPD) PPD)]
Combines two ◊pyret-id{PPrintDoc}s into a single document.
◊ppd-method["_output" #:contract (a-ftype A)]
Internal method for displaying the structure of this ◊pyret-id{PPrintDoc}.
◊ppd-method["pretty" #:contract (a-ftype (a-var-type "width" N) (L-of S))]
Renders this ◊pyret-id{PPrintDoc} at the desired line width.  Returns a list of
the individual lines of output.
  
  ◊section[#:tag-prefix "pprint_Functions"]{Functions}
  ◊function["str" #:contract (a-ftype (a-var-type "s" A) A)]{Constructs a document containing the given string.  Any
  whitespace in this string is considered unbreakable.}
  ◊function["number" #:contract (a-ftype (a-var-type "n" N) A)]{Constructs a document containing the number ◊math{n} printed as a
  string.  This is merely a convenient shorthand for
  ◊pyret-id{str}◊pyret{(}◊pyret-id["tostring" "<global>"]◊pyret{(n))}.}
  ◊function["blank" #:contract (a-ftype (a-var-type "n" A) A)]{Produces the requested number of non-breaking spaces.}
  ◊function["sbreak" #:contract (a-ftype (a-var-type "n" A) A)]{When typeset in flat mode, this produces the requested
  number of non-breaking spaces.  When typeset in vertical mode, produces a
  single linebreak.}
  ◊function["concat" #:contract (a-ftype (a-var-type "fst" A) (a-var-type "snd" A) A)]{Combines two documents into one, consecutively.}
  ◊function["nest" #:contract (a-ftype (a-var-type "n" A) (a-var-type "d" A) A)]{Adds ◊math{n} to the current indentation level while
  typesetting the given document.}
  ◊function["if-flat" #:contract (a-ftype (a-var-type "flat" A) (a-var-type "vert" A) A)]{Allows choosing between two documents, depending on
  whether this combined document is typeset in flat mode or not.}
  ◊function["group" #:contract (a-ftype (a-var-type "d" A) A)]{Wraps the given document in a group, so that it can be
  typeset in flat mode (if possible) even if the surrounding document is in
  vertical mode.  This helps ensure that linebreaks happen at the ``outer''
  layers of the document, and nested groups stay intact whenever possible.}
  ◊function["flow" #:contract (a-ftype (a-var-type "items" A) A)]{Combines a given list of documents with soft line breaks.
  When given a list of words, for example, this produces a paragraph that
  automatially line-wraps to fit the available space.}
  ◊function["vert" #:contract (a-ftype (a-var-type "items" A) A)]{Combines a given list of documents with hard line breaks.
  Note that unless the individual items are ◊pyret-id{group}ed, this will cause
  them all to be typeset vertically as well.}
  ◊function["flow-map"  #:contract (a-ftype (a-var-type "sep" A) (a-var-type "f" A) (a-var-type "items" A) A)]{A shorthand to ◊pyret-id["map" "lists"] a given list of values into a list
  of documents, then combine them with some separator via ◊pyret-id{separate}.}
  ◊function["parens" #:contract (a-ftype (a-var-type "d" A) A)]{Surrounds the given document in parentheses, and
  surrounds them all in a ◊pyret-id{group}.}
  ◊function["braces" #:contract (a-ftype (a-var-type "d" A) A)]{Surrounds the given document in curly braces, and
  surrounds them all in a ◊pyret-id{group}.}
  ◊function["brackets" #:contract (a-ftype (a-var-type "d" A) A)]{Surrounds the given document in square brackets, and
  surrounds them all in a ◊pyret-id{group}.}
  ◊function["dquote" #:contract (a-ftype (a-var-type "s" A) A)]{Surrounds the given document in double-quotes, and
  surrounds them all in a ◊pyret-id{group}.}
  ◊function["squote" #:contract (a-ftype (a-var-type "s" A) A)]{Surrounds the given document in single-quotes, and
  surrounds them all in a ◊pyret-id{group}.}
  ◊function["align" #:contract (a-ftype (a-var-type "d" A) A)]{Aligns the given document to the current column, wherever
  it might be.}
  ◊function["hang" #:contract (a-ftype (a-var-type "i" A) (a-var-type "d" A) A)]{Typesets the given document with a hanging indent of the
  given length.  The first line is typeset at the current position, and the
  remaining lines are all indented.}
  ◊function["prefix" #:contract (a-ftype (a-var-type "n" A) (a-var-type "b" A)(a-var-type "x" A)(a-var-type "y" A) A)]{Takes two documents and typesets them together as a
  pyret-id{group}.  If they can fit on one line, this is equivalent to
  concatenating them.  Otherwise, this increases the ◊pyret-id{nest}ing level
  of the second document by ◊math{n}.}
  ◊function["infix" #:contract (a-ftype (a-var-type "n" A) (a-var-type "b" A) (a-var-type "op" PPD) (a-var-type "x" PPD)(a-var-type "y" PPD) A)]{Typesets infix operators as a ◊pyret-id{group}, preferring to break lines after
  the operator.  Surrounds the operator with ◊math{b} blank spaces on either
  side, and indents any new lines by ◊math{n} spaces.}
  ◊function["infix-break" #:contract (a-ftype (a-var-type "n" A) (a-var-type "b" A) (a-var-type "op" PPD) (a-var-type "x" PPD)(a-var-type "y" PPD) A)]{Typesets infix operators as a ◊pyret-id{group}, preferring to break lines before
  the operator.  Surrounds the operator with ◊math{b} blank spaces on either
  side, and indents any new lines by ◊math{n} spaces.}
  ◊function["separate" #:contract (a-ftype (a-var-type "sep" PPD) (a-var-type "docs" "list.List") A )]{Interleaves each document of the provided list with the
  given separator document.}
  ◊function["surround" #:contract (a-ftype (a-var-type "n" N) (a-var-type "b" N) (a-var-type "open" PPD) (a-var-type "contents" PPD)(a-var-type "close" PPD) A)]{Given a document with many potential line breaks, and
  an opening and a closing document to surround it with, this function produces
  a document that either typesets everything on one line with ◊math{b} spaces
  between the contents and the enclosing documents, or typesets the opening,
  closing and contents on separate lines and indents the contents by ◊math{n}.
  Useful for typesetting things like data definitions, where each variant goes
  on its own line, as does the ◊pyret{data} and ◊pyret{end} keywords.}
  ◊function["soft-surround" #:contract (a-ftype (a-var-type "n" N) (a-var-type "b" N) (a-var-type "open" PPD) (a-var-type "contents" PPD)(a-var-type "close" PPD) A)]{Like ◊pyret-id{surround}, but tries to keep the
  closing document on the same line as the last line of the contents.  Useful
  for typesetting things like s-expressions, where the closing parentheses look
  better on the last line of the content.}
  ◊function["surround-separate" #:contract (a-ftype (a-var-type "n" N) (a-var-type "b" N) (a-var-type "void" PPD) (a-var-type "open" PPD) (a-var-type "sep" PPD)(a-var-type "close" PPD) (a-var-type "docs" "list.List") A)]{A combination of ◊pyret-id{surround} and
  ◊pyret-id{separate}.  Useful for typesetting delimited, comma-separated lists
  of items, or similar other other output.}
  ◊function["label-align-surround" #:contract (a-ftype (a-var-type "label" A) (a-var-type "open" A)   (a-var-type "sep" A)(a-var-type "contents" A)(a-var-type "close" A)  A)]{Similar to ◊pyret-id{soft-surround}, but
  with different alignment.}
}
