#lang pollen

◊(define (g-id name) (seclink (xref "<global>" name)))

◊(define (CC-of a) (a-app (a-id "CellContent" (xref "data-source" "CellContent")) a))
◊(define (San-of a) (a-app (a-id "Sanitizer" (xref "data-source" "Sanitizer")) a))



◊docmodule["data-source"]{
The general idea of loading a spreadsheet into a table is straightforward: each
cell of the spreadsheet corresponds to a cell of the table.  However,
spreadsheet files (such as Google Sheets or .csv files) store their data in a
serialized format, and loading the file must convert from that
representation back into useful Pyret data types.  Moreover, Pyret tables
expect each of their columns to be homogeneous, but there is nothing enforcing
that restriction on arbitrary spreadsheet files.

Accordingly, Pyret exposes a ◊pyret-id{CellContent} data type to record what
type it thinks each cell contains, and a ◊pyret-id{Sanitizer} to allow
enforcing a uniform type over all values in a column.  These two notions are
used by the ◊secref{gdrive-sheets} library to convert Google Sheets files into
Pyret ◊pyret-id["Table" "tables"]s.  A similar library could be written to use
these two types to load tables from .csv files or other data sources.

◊section{The CellContent Type}
◊data-spec2["CellContent" '("A") (list
◊singleton-spec2["CellContent" "c-empty"]
◊constructor-spec["CellContent" "c-str" (list `("s" ("type" "normal") ("contract" ,S)))]
◊constructor-spec["CellContent" "c-num" (list `("n" ("type" "normal") ("contract" ,N)))]
◊constructor-spec["CellContent" "c-bool" (list `("b" ("type" "normal") ("contract" ,B)))]
◊constructor-spec["CellContent" "c-custom" (list `("datum" ("type" "normal") ("contract" ,(a-id "A"))))]
)]

◊nested[#:style 'inset]{
◊singleton-doc["CellContent" "c-empty" (CC-of "A")]
◊constructor-doc["CellContent" "c-str" (list `("n" ("type" "normal") ("contract" ,S))) (CC-of "a")]{
}
◊constructor-doc["CellContent" "c-num" (list `("s" ("type" "normal") ("contract" ,N))) (CC-of "a")]{
}
◊constructor-doc["CellContent" "c-bool" (list `("b" ("type" "normal") ("contract" ,B))) (CC-of "a")]{
}
◊constructor-doc["CellContent" "c-custom" (list `("datum" ("type" "normal") ("contract" ,(a-id "A")))) (CC-of "A")]{
}
  ◊function["is-c-empty" #:contract (a-ftype (a-var-type "val" A) B) #:alt-docstrings ""]
  ◊function["is-c-str" #:contract (a-ftype (a-var-type "val" A) B) #:alt-docstrings ""]
  ◊function["is-c-num" #:contract (a-ftype (a-var-type "val" A) B) #:alt-docstrings ""]
  ◊function["is-c-bool" #:contract (a-ftype (a-var-type "val" A) B) #:alt-docstrings ""]
  ◊function["is-c-custom" #:contract (a-ftype (a-var-type "val" A) B) #:alt-docstrings ""]

This datatype describes Pyret's 
}


◊section{Sanitizers}
◊type-spec["Sanitizer" (list "A" "B")]{
A ◊pyret{Sanitizer<A, B>} is a function with signature
◊pyret{(}◊pyret-id{CellContent}◊pyret{<A>, }◊g-id{String}◊pyret{,
}◊g-id{Number}◊pyret{ -> B}◊pyret{)}.  It takes in the contents of a cell, as
well as the coordinates (column name, as given by the ◊seclink["s:tables:loading"]{◊pyret{load-table}
header}, and zero-indexed row number) of that cell, and attempts to parse the
contents of that cell to a value of the intended Pyret type.  If a cell's
contents cannot be parsed, the sanitizer may raise an error explaining the problem.
}

◊subsection{Pre-defined sanitizers}
◊function["string-sanitizer"
  #:contract (a-ftype (a-var-type "x" (CC-of "A")) (a-var-type "col" S) (a-var-type "row"  N) S)
  #:args `(("x" "") ("col" "") ("row" ""))
  #:return S
]

This sanitizer tries to convert ◊pyret-id{CellContent}s containing anything to
a ◊g-id{String}, by calling ◊g-id{tostring} on it.

◊function["num-sanitizer"
  #:contract (a-ftype (a-var-type "x" (CC-of "A")) (a-var-type "col" S) (a-var-type "row"  N) S)
  #:args `(("x" "") ("col" "") ("row" ""))
  #:return N
]

This sanitizer tries to convert ◊pyret-id{CellContent}s containing numbers,
strings, or booleans to a ◊g-id{Number}.  Strings are attempted to be parsed.
True and false convert to 1 and 0 respectively.  Any other values are rejected,
including blank cells.

◊function["bool-sanitizer"
  #:contract (a-ftype (a-var-type "x" (CC-of "A")) (a-var-type "col" S) (a-var-type "row"  N) S)
  #:args `(("x" "") ("col" "") ("row" ""))
  #:return B
]

This sanitizer tries to convert ◊pyret-id{CellContent}s containing numbers,
strings, or booleans to a ◊g-id{Boolean}.  0 and 1 convert to ◊pyret{false}
and ◊pyret{true} respectively.  The (case-insensitive) strings ◊pyret{"true"}
and ◊pyret{"false"} convert appropriately.  Any other values are rejected,
including blank cells.

◊function["strict-num-sanitizer"
  #:contract (a-ftype (a-var-type "x" (CC-of "A")) (a-var-type "col" S) (a-var-type "row"  N) S)
  #:args `(("x" "") ("col" "") ("row" ""))
  #:return N
]

This sanitizer tries to convert ◊pyret-id{CellContent}s containing strings or
numbers to a ◊g-id{Number}.  Strings are attempted to be parsed.  Any other
values are rejected, including blank cells.

◊function["strings-only"
  #:contract (a-ftype (a-var-type "x" (CC-of "A")) (a-var-type "col" S) (a-var-type "row"  N) S)
  #:args `(("x" "") ("col" "") ("row" ""))
  #:return S
]

This sanitizer accepts ◊pyret-id{CellContent}s containing strings only, and
rejects all other values, including blank cells.

◊function["booleans-only"
  #:contract (a-ftype (a-var-type "x" (CC-of "A")) (a-var-type "col" S) (a-var-type "row"  N) S)
  #:args `(("x" "") ("col" "") ("row" ""))
  #:return B
]

This sanitizer accepts ◊pyret-id{CellContent}s containing booleans only, and
rejects all other values, including blank cells.

◊function["numbers-only"
  #:contract (a-ftype (a-var-type "x" (CC-of "A")) (a-var-type "col" S) (a-var-type "row"  N) S)
  #:args `(("x" "") ("col" "") ("row" ""))
  #:return N
]

This sanitizer accepts ◊pyret-id{CellContent}s containing numbers only, and
rejects all other values, including blank cells.

◊function["empty-only"
  #:contract (a-ftype (a-var-type "x" (CC-of "A")) (a-var-type "col" S) (a-var-type "row"  N) S)
  #:args `(("x" "") ("col" "") ("row" ""))
  #:return (O-of "A")
]

This sanitizer accepts ◊pyret-id{CellContent}s containing blank cells only, and
rejects all other values.

◊function["option-sanitizer"
  #:contract (a-ftype (San-of "A") (San-of (O-of "A")))
  #:args `(("value-sanitizer" ""))
  #:return (San-of (O-of "A"))
]

This higher-order sanitizer takes in another sanitizer that does not expect to
be given blank cells, and produces a new sanitizer that can accept them.  Blank
cells are converted to ◊pyret-id["none" "option"], while valid non-blank cells
are converted to a ◊pyret-id["some" "option"] value containing the converted
contents of the cell.  Values rejected by the ◊pyret{value-sanitizer} are
rejected by this sanitizer as well.

This sanitizer is useful for handling incomplete data that might contain blank
values; a subsequent processing step could filter out the ◊pyret-id["none"
"option"] values.

}
