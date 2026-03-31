#lang pollen

◊(define (a-ref name)
  (pyret-method "List" "shared methods" name "lists"))

◊; WARNING in report-undocumented: Undocumented export "join-str" from module "lists"
◊; WARNING in report-undocumented: Undocumented export "push" from module "lists"



◊(define (list-method name #:contract [contract #f])
  (method-doc "List" #f name #:contract contract #:alt-docstrings ""))

◊docmodule["lists"]{
  ◊ignore[(list)]

  ◊section{The List Datatype}

  ◊data-spec2["List" (list "a") (list
  ◊singleton-spec2["List" "empty"]
  ◊constructor-spec["List" "link" (list `("first" ("type" "normal") ("contract" ,(a-id "a"))) `("rest" ("type" "normal") ("contract" ,(L-of "a"))))])]

  ◊nested[#:style 'inset]{
  ◊singleton-doc["List" "empty" (L-of "a")]
  ◊constructor-doc["List" "link" (list `("first" ("type" "normal") ("contract" ,(a-id "a"))) `("rest" ("type" "normal") ("contract" ,(L-of "a")))) (L-of "a")]{
  }

  ◊function["is-empty" #:contract (a-ftype (a-var-type "val" A) B)]

  ◊function["is-link" #:contract (a-ftype (a-var-type "val" A) B)]

A ◊pyret{List} is an immutable, fixed-length collection indexed by
non-negative integers.
  
As in most programming languages, you can use ◊pyret{List}s in Pyret
without understanding much, if anything, about how they are 
implemented internally in the language.  

However, in functional languages such as Pyret a particular
implementation of lists — the linked list — has a central
role for both historical and practical reasons, and a fuller
understanding of linked lists goes hand in hand with a fuller
understanding of Pyret.  If you have not encountered linked
lists before and would like to know more, we recommend reading
◊link["http://dcic-world.org/" "the material on
lists in DCIC"].

In lieu of a full explanation on this page, here are a few quick points
to help parse some of the following examples:
◊itemlist[◊item{A ◊pyret{List} is made up of elements, usually
referred to as ◊tt{elt}s in examples.}
◊item{Elements are of two types: ◊pyret{link} and ◊pyret{empty}.}
◊item{Every ◊pyret{link} actually has two parts: a ◊bold{first} value and the
◊bold{rest} of the ◊pyret{List}.}
◊item{The rest of the ◊pyret{List} is itself a ◊pyret{link}, or if you
have reached the end of the ◊pyret{List}, the rest will be ◊pyret{empty}.}
]
and here are some illustrative examples:
◊examples[#:show-try-it #t]{
check:
  l0 = empty
  l1 = link(1, l0)
  l2 = link(2, l1)
  is-empty(l0) is true
  is-link(l0) is false
  
  is-empty(l1) is false
  is-link(l1) is true
  
  is-empty(l2) is false
  is-link(l2) is true
end
}

  }

◊section{List Creation Functions}

◊collection-doc["list" #:fields (list (a-var-type "elt" "a")) #:return (L-of "a")]

◊margin-note{This illustrates the underlying structure created when
you define a ◊pyret{List} with ◊pyret{[list: ...]}}

Constructs a ◊pyret{List} out of ◊pyret{elt}s by chaining ◊pyret-id{link}s,
ending in a single ◊pyret-id{empty}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: ] is L.empty
  [L.list: 1] is L.link(1, L.empty)
  [L.list: 1, 2] is L.link(1, link(2, L.empty))
end
}

Though it is neither required nor enforced by the language,
conventionally, when writing the empty list using the constructor
notation, we write an extra spce between the ◊pyret{:} and ◊pyret{]}.

◊bold{Note}: You should ◊emph{not} write a trailing ◊pyret-id{empty}
when using this constructor notation. Everything you write is an ◊emph{element} of the list. Thus,
◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: ] is-not [L.list: L.empty]
  L.link(L.empty, L.empty) is [L.list: L.empty]
end
}

◊function["build-list"
  #:contract (a-ftype (a-var-type "f" (a-ftype N "a"))
                      (a-var-type "size" N)
                      (L-of "a") )
]

Constructs a list of length ◊pyret{size}, and fills it with the result of
calling the function ◊pyret{f} with each index from ◊pyret{0} to ◊pyret{size - 1}.

Similar to ◊pyret-id["build-array" "arrays"].

◊examples[#:show-try-it #t]{
import lists as L

check:
  fun sq(x): x * x end
  L.build-list(sq, 4) 
    is [L.list: 0, 1, 4, 9]
    because [L.list: sq(0), sq(1), sq(2), sq(3)]
end

check:
  fun build-from(base :: Number) -> List<String>:
    L.build-list({(n): base + n}, 3)
  end

  a = L.build-list(build-from, 3)
  
  a is [L.list:
    [L.list: 0, 1, 2],
    [L.list: 1, 2, 3],
    [L.list: 2, 3, 4]]
end
}


◊section{List Methods}

These methods are available on all ◊pyret{List}s whether empty or a link.

◊list-method["length" #:contract (a-ftype N)]

Returns the number of elements in the ◊pyret{List}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 'a', 'b'].length() is 2
  L.empty.length() is 0
  L.link("a", L.empty).length() is 1
end
}

◊list-method["map"
  #:contract (a-ftype (a-var-type "f" (p-a-ftype "a" "b")) (L-of "b")) ]


Applies function ◊pyret{f} to each element of the list from left to right, and
constructs a new ◊pyret{List} out of the return values in the corresponding order.

◊tt{a} represents the type of the elements in the original ◊pyret{List}, ◊tt{b} is
the type of the elements in the new ◊pyret{List}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2].map(num-tostring) is [L.list: "1", "2"]
  [L.list: 1, 2].map(lam(n): n + 1 end) is [L.list: 2, 3] 
  [L.list: 1, 2].map(_ + 1) is [L.list: 2, 3]
  L.empty.map(lam(x): raise("This never happens!") end) is L.empty
end
}

◊list-method["each"
 #:contract (a-ftype (a-var-type "f" (p-a-ftype "a" No)) No)
]

Applies ◊pyret{f} to each element of the ◊pyret{List} from left to right, and
returns ◊pyret{nothing}.  Because it returns ◊pyret{nothing},
use ◊pyret-id{each} instead of ◊pyret-id{map} when the function
◊pyret{f} is needed only for its side-effects.

◊examples[#:show-try-it #t]{
import lists as L

check:
  var x = 1
  [L.list: 1, 2].each(lam(n): x := x + n end) is nothing
  x is 4
end
}

◊list-method["filter"
  #:contract (a-ftype (a-var-type "f" (p-a-ftype "a" B)) (L-of "a"))
]

Applies function ◊pyret{f} to each element of ◊pyret{List} from left to right,
constructing a new ◊pyret{List} out of the elements for which ◊pyret{f}
returned ◊pyret{true}.

The original ◊pyret{List} elements are of type ◊tt{a}
and the function ◊pyret{f} must return a ◊pyret{Boolean}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  fun length-is-one(s :: String) -> Boolean:
    string-length(s) == 1
  end
  [L.list: "ab", "a", "", "c"].filter(length-is-one) is [L.list: "a", "c"]
  [L.list: L.empty, L.link(1, L.empty), L.empty].filter(L.is-link)
    is [L.list: L.link(1, L.empty)]
end
}

◊list-method["push"
  #:contract (a-ftype (a-var-type "elt" "a") (L-of "a"))]

Returns ◊tt{link(elt, self)}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  L.empty.push("a") is L.link("a", L.empty)
  L.link("a", L.empty).push("b") is L.link("b", L.link("a", L.empty))
end
}

In other words, returns a ◊pyret{List} with ◊tt{elt} appended to the
beginning of the original ◊pyret{List}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 'a', 'b'].push('c') is [L.list: 'c', 'a', 'b']
end
}


◊list-method["split-at"
  #:contract (a-ftype (a-var-type "n" N)
              (a-tuple
                (a-var-type "prefix" (L-of "a"))
                (a-var-type "suffix" (L-of "a"))))
]
Produces a record containing two ◊pyret{List}s, consisting of the items before
and the items at-or-after the
splitting index of the current ◊pyret{List}.  The index is 0-based, so
splitting a ◊pyret{List} at index ◊math{n} will produce a prefix of length
exactly ◊math{n}.  Moreover, ◊pyret-id{append}ing the two ◊pyret{List}s
together will be equivalent to the original ◊pyret{List}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 'a', 'b', 'c', 'd'].split-at(2)
    is {prefix: [L.list: "a", "b"], suffix: [L.list: "c", "d"]}
  one-four = L.link(1, L.link(2, L.link(3, L.link(4, L.empty))))
  one-four.split-at(0) is {prefix: L.empty, suffix: one-four}
  one-four.split-at(4) is {prefix: one-four, suffix: L.empty}
  one-four.split-at(2) is
  {prefix: [L.list: 1, 2], suffix: [L.list: 3, 4]}
  one-four.split-at(-1) raises "Invalid index"
  one-four.split-at(5) raises "Index too large"
end
}

◊list-method["take"
 #:contract (a-ftype (a-var-type "n" N) (L-of "a"))]
Given a length ◊tt{n}, returns a new ◊pyret{List} containing the first
◊tt{n} items of the ◊pyret{List}.


◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2, 3, 4, 5, 6].take(3) is [L.list: 1, 2, 3]
  [L.list: 1, 2, 3].take(6) raises "Index too large"
  [L.list: 1, 2, 3].take(-1) raises "Invalid index"
end
}

◊list-method["drop"
 #:contract (a-ftype (a-var-type "n" N) (L-of "a"))]
]
Given a length ◊tt{n}, returns a ◊pyret{List} containing all but the first ◊tt{n} items of the ◊pyret{List}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2, 3, 4, 5, 6].drop(3) is [L.list: 4, 5, 6]
end
}

◊list-method["get"
  #:contract (a-ftype (a-var-type "n" N) "a")
]
Returns the ◊tt{n}th element of the given ◊pyret{List}.

Using an index too large, negative, or not a whole number raises an error.

◊examples[#:show-try-it #t]{
import lists as L

check:
  l = [L.list: 1, 2, 3]

  l.get(0) is 1
  l.get(4) raises "too large"
  l.get(-1) raises "invalid argument"
end
}

◊list-method["set"
  #:contract (a-ftype (a-var-type "n" N) (a-var-type "e" "a") (L-of "a"))
]
Returns a new ◊pyret{List} with the same values as the given ◊pyret{List} but with the ◊tt{n}th element set to the
given value, or raises an error if ◊tt{n} is out of range.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2, 3].set(0, 5) is [L.list: 5, 2, 3]
  [L.list: ].set(0, 5) raises "too large"
end
}

◊list-method["foldl"
  #:contract (a-ftype (a-var-type "f" (p-a-ftype "a" "Base" "Base"))
                      (a-var-type "base" "Base")
                      "Base")
]

Computes ◊pyret{f(last-elt, ... f(second-elt, f(first-elt, base))...)}.  For
◊pyret-id{empty}, returns ◊pyret{base}.

In other words, ◊pyret{.foldl} uses the function ◊tt{f}, starting with the ◊tt{base}
value, of type ◊tt{Base}, to calculate the return value of type ◊tt{Base} from each
item in the ◊pyret{List}, of input type ◊tt{Elt}, starting the sequence from the ◊emph{left} (hence, fold◊bold{l}).

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 3, 2, 1].foldl(lam(elt, acc): elt + acc end, 10) is 16
  fun combine(elt, acc) -> String:
    tostring(elt) + " - " + acc
  end
  [L.list: 3, 2, 1].foldl(combine, "END") is "1 - 2 - 3 - END"
  L.empty.foldl(combine, "END") is "END"
  [L.list: 3, 2, 1].foldl(L.link, L.empty) is [L.list: 1, 2, 3]
end
}

◊list-method["foldr"
  #:contract (a-ftype (a-var-type "f" (p-a-ftype "a" "Base" "Base"))
                      (a-var-type "base" "Base")
                      "Base")
]

Computes ◊pyret{f(first-elt, f(second-elt, ... f(last-elt, base)))}.  For
◊pyret-id{empty}, returns ◊pyret{base}. 

In other words, ◊pyret{.foldr} uses the function ◊tt{f}, starting with the ◊tt{base}
value, of type ◊tt{Base}, to calculate the return value of type ◊tt{Base} from each
item in the ◊pyret{List}, of input type ◊tt{Elt}, starting the sequence from the ◊emph{right} (hence, fold◊bold{r}).

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 3, 2, 1].foldr(lam(elt, acc): elt + acc end, 10) is 16
  fun combine(elt, acc) -> String: 
    tostring(elt) + " - " + acc 
  end
  [L.list: 3, 2, 1].foldr(combine, "END") is "3 - 2 - 1 - END"
  empty.foldr(combine, "END") is "END"
  [L.list: 3, 2, 1].foldr(L.link, L.empty) is [L.list: 3, 2, 1]
end
}

◊list-method["member"
  #:contract (a-ftype (a-var-type "elt" "a") B)]
◊margin-note{Passing a ◊pyret{Roughnum} as an argument will raise
an error.}
Returns true if the current ◊pyret{List} contains the given value, as compared
by ◊pyret{==}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2, 3].member(2) is true
  [L.list: 2, 4, 6].member(3) is false
  [L.list: ].member(L.empty) is false
  [L.list: 1, 2, 3].member(~1) raises "Roughnums"
  [L.list: ~1, 2, 3].member(1) raises "Roughnums"
  [L.list: 1, 2, 3].member(4) is false
  [L.list: 1, 2, 3].member(~4) raises "Roughnums"

  [L.list: 'a'].member('a') is true
  [L.list: false].member(false) is true
  [L.list: nothing].member(nothing) is true
end
}

◊list-method["append"
  #:contract (a-ftype (a-var-type "other" (L-of "a")) (L-of "a"))
]
Produces a new ◊pyret{List} with all the elements of the current ◊pyret{List},
followed by all the elements of the ◊tt{other} ◊pyret{List}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2].append([list: 3, 4]) is [L.list: 1, 2, 3, 4]
  L.empty.append([L.list: 1, 2]) is [L.list: 1, 2]
  [L.list: 1, 2].append(empty) is [L.list: 1, 2]
end
}

◊list-method["last"
  #:contract (a-ftype "a")
]
Returns the last item of the ◊pyret{List}.
◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2, 3].last() is 3
  L.empty.last() raises "last of empty list"
end
}

◊list-method["reverse"
  #:contract (a-ftype (L-of "a"))
]
Produces a new ◊pyret{List} with the items of the original ◊pyret{List} in reversed order.
◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2, 3].reverse() is [L.list: 3, 2, 1]
  L.empty.reverse() is L.empty
end
}

◊list-method["sort"
  #:contract (a-ftype (L-of "a"))
]
Produces a new ◊pyret{List} whose contents are the same as those of the
current ◊pyret{List}, sorted by ◊pyret-id["<" "equality"] and
◊pyret-id["==" "equality"].  This requires that
the items of the ◊pyret{List} be comparable by ◊pyret-id["<" "equality"] (see
◊secref["s:binop-expr"]).

◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 5, 3, 2, 4].sort() is [L.list: 1, 2, 3, 4, 5]
  [L.list: "aaaa", "B", "a"].sort() is [L.list: "B", "a", "aaaa"]
  [L.list: 'a', 1].sort() raises "binop-error"
  [L.list: true, false].sort() raises "binop-error"
end
}

◊list-method["sort-by"
  #:contract (a-ftype (a-var-type "cmp" (a-ftype "a" "a" B))
                      (a-var-type "eq" (a-ftype "a" "a" B))
                      (L-of "a"))
]
Like ◊pyret-id{sort}, but the comparison and equality operators can be
specified.  This allows for sorting ◊pyret{List}s whose contents are not
comparable by ◊pyret{<}, or sorting by custom comparisons, for example,
sorting by string length instead of alphabetically.

◊examples[#:show-try-it #t]{
import lists as L

check:
  fun length-comparison(s1 :: String, s2 :: String) -> Boolean:
    string-length(s1) > string-length(s2)
  end
  fun length-equality(s1 :: String, s2 :: String) -> Boolean:
    string-length(s1) == string-length(s2)
  end
  [L.list: 'a', 'aa', 'aaa'].sort-by(length-comparison, length-equality) is
    [L.list: 'aaa', 'aa', 'a']
end
}

◊list-method["join-str"
#:contract (a-ftype (a-var-type "sep" S) S)
]
Combines the values of the current ◊pyret{List} by converting them to strings
with ◊pyret{tostring} and joining them with the given separator ◊pyret{sep}.
◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2, 3].join-str("; ") is "1; 2; 3"
  [L.list: "a", true, ~5.3].join-str(" : ") is "a : true : ~5.3"
  L.empty.join-str("nothing at all") is ""
end
}


◊list-method["join-str-last"
  #:contract (a-ftype (a-var-type "sep" S)
                       (a-var-type "last-sep" S)
                       S)

]
Combines the values of the current ◊pyret{List} by converting them to strings
with ◊pyret{tostring} and joining them with the given separator ◊pyret{sep}.
If the list has more than one element, the function will use ◊pyret{last-sep}
to join the last element instead of the regular ◊pyret{sep}.
◊examples[#:show-try-it #t]{
import lists as L

check:
  [L.list: 1, 2, 3].join-str-last(", ", " and ") is "1, 2 and 3"
  [L.list: "a", true, ~5.3].join-str-last(" : ", " # ") is "a : true # ~5.3"
  L.empty.join-str-last("nothing at all", "really nothing") is ""
  [L.list: 1, 2].join-str-last("a", "b") is "1b2"
  [L.list: 1].join-str-last("a", "b") is "1"
end
}

◊section{List Functions}

  These functions are available on the ◊pyret{lists} module object.
  Some of the functions require the ◊pyret{lists} module to be
  ◊pyret{import}ed, as indicated in the examples.

  ◊function["length"
    #:contract (a-ftype (a-var-type "lst" (L-of "a")) N)
  ]{

  Returns the number of elements in the ◊pyret{List}.

  ◊examples[#:show-try-it #t]{
import lists as L

check:
  L.length([list: 'a', 'b']) is 2
  L.length(L.empty) is 0
  L.length(L.link("a", L.empty)) is 1
end
  }

  }

  
  ◊function[
    "get"
    #:contract (a-ftype (a-var-type "lst" (L-of "a"))
                        (a-var-type "n" N) "a")
  ]

Equivalent to ◊pyret{list}◊a-ref["get"]◊pyret{(n)}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  l = [L.list: 1, 2, 3]

  L.get(l, 0) is 1
  L.get(l, 4) raises "too large"
  L.get(l, -1) raises "invalid argument"
end
    }

  ◊function[
    "set"
    #:contract (a-ftype (a-var-type "lst" (L-of "a"))
    (a-var-type "n" N) (a-var-type "v" "a")
    (L-of "a"))]

    ◊examples{
import lists as L

check:
  L.set([L.list: 1, 2, 3], 0, 5) is [L.list: 5, 2, 3]
  L.set([L.list: ], 0, 5) raises "too large"
end
    }

◊function["sort"
  #:contract (a-ftype (L-of "A") (L-of "A"))
  #:args '(("lst" #f))
  #:return (L-of "A")]{
Produces a new ◊pyret{List} whose contents are the same as those of the
current ◊pyret{List}, sorted by ◊pyret-id["<" "equality"] and ◊pyret-id["==" "equality"].  This requires that
the items of the ◊pyret{List} be comparable by ◊pyret-id["<" "equality"] (see ◊secref["s:binop-expr"]).
◊examples[#:show-try-it #t]{
import lists as L

check:
  L.sort([L.list: 1, 5, 3, 2, 4]) is [L.list: 1, 2, 3, 4, 5]
  L.sort([L.list: "aaaa", "B", "a"]) is [L.list: "B", "a", "aaaa"]
  L.sort([L.list: 'a', 1]) raises "binop-error"
  L.sort([L.list: true, false]) raises "binop-error"
end
}
}

◊function["sort-by"
  #:contract (a-ftype (L-of "A") (a-ftype "A" "A" (a-id "Boolean" (xref "<global>" "Boolean"))) (a-ftype "A" "A" (a-id "Boolean" (xref "<global>" "Boolean"))) (L-of "A"))
  #:args '(("lst" #f) ("cmp" #f) ("eq" #f))
  #:return (L-of "A")]{
Like ◊pyret-id{sort}, but the comparison and equality operators can be
specified.  This allows for sorting ◊pyret{List}s whose contents are not
comparable by ◊pyret-id["<" "equality"],  or sorting by custom comparisons, for example,
sorting by string length instead of alphabetically.
◊examples[#:show-try-it #t]{
import lists as L

check:
  fun length-comparison(s1 :: String, s2 :: String) -> Boolean:
    string-length(s1) > string-length(s2)
  end
  fun length-equality(s1 :: String, s2 :: String) -> Boolean:
    string-length(s1) == string-length(s2)
  end
  L.sort-by([L.list: 'a', 'aa', 'aaa'], length-comparison, length-equality) is
    [L.list: 'aaa', 'aa', 'a']
end
}
}

◊function["join-str"
  #:contract (a-ftype (a-var-type "sep" S) S)
          ]

◊examples{
import lists as L

check:
  [L.list: 1, 2, 3].join-str("; ") is "1; 2; 3"
  [L.list: "a", true, ~5.3].join-str(" : ") is "a : true : ~5.3"
  L.empty.join-str("nothing at all") is ""
end
}




  ◊function[
    "range"
    #:contract (a-ftype (a-var-type "start" N) (a-var-type "stop" N) (L-of N))
    ]
    ◊examples{
    check:
      range(0, 0) is [list: ]
      range(0, 1) is [list: 0]
      range(-5, 5) is [list: -5, -4, -3, -2, -1, 0, 1, 2, 3, 4]
    end
    }

  ◊function["range-by"
  #:contract (a-ftype (a-var-type "start" N) (a-var-type "stop" N) (a-var-type "delta" N) (L-of N))]
  ◊examples[#:show-try-it #t]{
import lists as L

check:
  L.range-by(1, 10, 4) is [L.list: 1, 5, 9]
  L.range-by(10, 1, -4) is [L.list: 10, 6, 2]
  L.range-by(3, 20, 9) is [L.list: 3, 12]
  L.range-by(20, 3, 9) is L.empty
  L.range-by(20, 3, -9) is [L.list: 20, 11]
  L.range-by(2, 3, 0) raises "interval of 0"
end
  }

  ◊function[
    "repeat"
    #:contract (a-ftype (a-var-type "n" N) (a-var-type "e" "a") (L-of "a"))
    ]
    ◊examples{
import lists as L

check:
  L.repeat(0, 10) is L.empty
  L.repeat(3, -1) is [L.list: -1, -1, -1]
  L.repeat(1, "foo") is L.link("foo", L.empty)
  L.repeat(3, L.empty) is [L.list: [L.list: ], [L.list: ], [L.list: ]]
end
    }

  ◊function["distinct"
    #:contract (a-ftype (a-var-type "lst" (L-of "a")) (L-of "a"))
  ]{

  Given a ◊pyret{List}, returns a new ◊pyret{List} containing only one copy of each element
  that is duplicated in the ◊pyret{List}.

  The last (latest in the ◊pyret{List}) copy is kept.
  ◊pyret{Roughnums} are not compared for equality, and so will always appear in the
  output ◊pyret{List}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  L.distinct([L.list: 3, 1, 2, 2, 3, 2]) is [L.list: 1, 3, 2]
  L.distinct([L.list: ~1, ~1]) is-roughly [L.list: ~1, ~1]
  L.distinct([L.list: ~1, ~1, 1]) is-roughly [L.list: ~1, ~1, 1]
  L.distinct([L.list: ~1, ~1, 1, 1]) is-roughly [L.list: ~1, ~1, 1]
  L.distinct([L.list: ~1, ~2, ~3]) is-roughly [L.list: ~1, ~2, ~3]
end
}

  }


  ◊function[
    "filter"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" B))
    (a-var-type "lst" (L-of "a")) (L-of "a"))
  ]
    ◊examples{
import lists as L

check:
  fun length-is-one(s :: String) -> Boolean:
    string-length(s) == 1
  end
  L.filter(length-is-one, [L.list: "ab", "a", "", "c"]) 
    is [L.list: "a", "c"]
  L.filter(is-link, [L.list: L.empty, L.link(1, L.empty), L.empty])
    is [L.list: L.link(1, L.empty)]
end
    }

  ◊function[
    "partition"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" B))
    (a-var-type "lst" (L-of "a"))
    (a-tuple (a-var-type "is-true" (L-of "a"))
      (a-var-type "is-false" (L-of "a"))))
  ]
    ◊examples{
import lists as L

check:
  L.partition(lam(e): e > 0 end, [L.list: -1, 1])
    is {is-true: [L.list: 1], is-false: [L.list: -1]}
  L.partition(lam(e): e > 5 end, [L.list: -1, 1])
    is {is-true: [L.list: ], is-false: [L.list: -1, 1]}
  L.partition(lam(e): e < 5 end, [L.list: -1, 1])
    is {is-true: [L.list: -1, 1], is-false: [L.list: ]}
end
    }

◊function[
    "find"
    #:contract (a-ftype (a-var-type "f" (p-a-ftype "a" B))
    (a-var-type "lst" (L-of "a"))
    (O-of "a"))
  ]
◊examples[#:show-try-it #t]{
import lists as L
import option as O

check:
  L.find(num-is-integer,  [L.list: 2.5, 3.5, 100, 2, 4.5]) is O.some(100)
  L.find(num-is-rational, [L.list: 2.5, 3.5, 100, 2, 4.5]) is O.some(2.5)
  L.find(num-is-negative, [L.list: 2.5, 3.5, 100, 2, 4.5]) is O.none
  L.find(lam(n): n <= 2 end, [L.list: 2.5, 3.5, 100, 2, 4.5]) is O.some(2)
  L.find(lam(n): n < 1 end, [L.list: 2.5, 3.5, 100, 2, 4.5]) is O.none
end
    }

  ◊function[
    "split-at"
    #:contract (a-ftype
    (a-var-type "n" N)
    (a-var-type "lst" (L-of "a"))
    (a-tuple (a-var-type "prefix" (L-of "a"))
      (a-var-type "suffix" (L-of "a"))))
  ]
    ◊examples{
import lists as L

check:
  L.split-at(2, [L.list: 'a', 'b', 'c', 'd']) 
    is {prefix: [L.list: "a", "b"], suffix: [L.list: "c", "d"]}
  L.split-at(0, [L.list: 1, 2, 3, 4]) 
    is {prefix: L.empty, suffix: [L.list: 1, 2, 3, 4]}
  L.split-at(4, [L.list: 1, 2, 3, 4])
    is {prefix: [L.list: 1, 2, 3, 4], suffix: L.empty}
  L.split-at(2, [L.list: 1, 2, 3, 4]) 
    is {prefix: [L.list: 1, 2], suffix: [L.list: 3, 4]}
  L.split-at(-1, [L.list: 1, 2, 3, 4]) raises "Invalid index"
  L.split-at(5, [L.list: 1, 2, 3, 4]) raises "Index too large"
end
    }

  ◊function["last"
    #:contract (a-ftype (a-var-type "lst" (L-of "A")) "A")
    #:return "A"
    #:args '(("lst" #f))]{

  Returns the last element in ◊pyret{lst}.  Raises an error if the ◊pyret{List} is
  empty.

  ◊examples[#:show-try-it #t]{
import lists as L

check:
  L.last([L.list: 1, 3, 5]) is 5
  L.last([L.list: 1]) is 1
  L.last([L.list: ]) raises "last of empty list"
end
  }

  }

◊function["push"
#:contract (a-ftype (a-var-type "l" (L-of "A")) (a-var-type "elt" "A") (L-of "A"))
#:args '(("l" #f) ("elt" #f))
#:return (L-of "A")]{
Constructs a list with the given element prepended to the front of the given
list.
◊examples[#:show-try-it #t]{
import lists as L

check:
  L.push(L.empty, "a") is L.link("a", L.empty)
  L.push(L.link("a", empty), "b") is L.link("b", L.link("a", L.empty))
end
}
}

  ◊function["append"
    #:contract (a-ftype (a-var-type "front" (L-of "A")) (a-var-type "back" (L-of "A")) (L-of "A"))
    #:return (L-of "A")
    #:args '(("front" #f) ("back" #f))]{

    Produce a new ◊pyret{List} with the elements of ◊pyret{front} followed by the
    elements of ◊pyret{back}.

    ◊pyret-block[#:style "good-ex"]{
import lists as L

check:
  L.append([L.list: 1, 2, 3], [L.list: 4, 5, 6])
    is [L.list: 1, 2, 3, 4, 5, 6]
  L.append([L.list: ], [L.list: ]) is [L.list: ]
  L.append([L.list: 1], [L.list: 2]) is [L.list: 1, 2]
end
    }

    Note that it does ◊emph{not} change either ◊pyret{List}:

    ◊pyret-block[#:style "bad-ex"]{
import lists as L

check:
  l = [L.list: 1, 2, 3]
  L.append(l, [L.list: 4])
  l is [L.list: 1, 2, 3, 4] # this test fails
end
    }

  }

  ◊function[
    "any"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" B))
    (a-var-type "lst" (L-of "a"))
    B)
  ]
    ◊examples{
import lists as L

check:
  L.any(is-number, [L.list: 1, 2, 3]) is true
  L.any(is-string, [L.list: 1, 2, 3]) is false
  L.any(lam(n): n > 1 end, [L.list: 1, 2, 3]) is true
  L.any(lam(n): n > 3 end, [L.list: 1, 2, 3]) is false
end
    }

  ◊function[
    "all"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" B))
    (a-var-type "lst" (L-of "a"))
    B)
  ]
    ◊examples{
import lists as L

check:
  L.all(is-number, [L.list: 1, 2, 3]) is true
  L.all(is-string, [L.list: 1, 2, 'c']) is false
  L.all(lam(n): n > 1 end, [L.list: 1, 2, 3]) is false
  L.all(lam(n): n <= 3 end, [L.list: 1, 2, 3]) is true
end
    }

  ◊function[
    "all2"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" "b" B))
    (a-var-type "lst1" (L-of "b"))
    (a-var-type "lst2" (L-of "b"))
    B)

  ]

When the ◊pyret{List}s are of different length, the function is only
called when both ◊pyret{List}s have a value at a given index.  In other words,
Pyret iterates over the shortest ◊pyret{List} and stops.
  
◊examples[#:show-try-it #t]{
import lists as L

check:
  L.all2(lam(n, m): n > m end, [L.list: 1, 2, 3], [L.list: 0, 1, 2]) is true
  L.all2(lam(n, m): (n + m) == 3 end, [L.list: 1, 2, 3], [L.list: 2, 1, 0]) is true
  L.all2(lam(n, m): (n + m) == 3 end, [L.list: 1, 2], [L.list: 2, 1, 0]) is true
  L.all2(lam(n, m): (n + m) == 3 end, [L.list: 1, 2, 6], [L.list: 2, 1]) is true
  L.all2(lam(n, m): n > m end, [L.list: 1, 2, 3], [L.list: 0, 1, 2]) is true
  L.all2(lam(n, m): n > m end, [L.list: 1, 2, 0], [L.list: 0, 1]) is true
  L.all2(lam(n, m): n < m end, [L.list: 1], [L.list: 2, 0]) is true
  L.all2(lam(n, m): n < m end, [L.list: 1, 2, 3], L.empty) is true
end
    }
  
  ◊function[
    "map"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" "b"))
    (a-var-type "lst" (L-of "a"))
    (L-of "b"))
  ]


◊examples[#:show-try-it #t]{
import lists as L

check:
  L.map(num-tostring, [L.list: 1, 2]) is [L.list: "1", "2"]
  L.map(lam(x): x + 1 end, [L.list: 1, 2]) is [L.list: 2, 3]
end
}
  ◊function[
    "map2"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" "b" "c"))
    (a-var-type "l1" (L-of "a"))
    (a-var-type "l2" (L-of "b"))
    (L-of "c"))
  ]

When the ◊pyret{List}s are of different length, the function is only
called when both ◊pyret{List}s have a value at a given index.  In other words,
Pyret iterates over the shortest ◊pyret{List} and stops.
  
◊examples[#:show-try-it #t]{
import lists as L

check:
  L.map2(string-append, [L.list: "mis", "mal"], [L.list: "fortune", "practice"])
    is [L.list: "misfortune", "malpractice"]
  L.map2(_ + _, [L.list: "mis", "mal"], [L.list: "fortune", "practice"])
    is [L.list: "misfortune", "malpractice"]
  L.map2(string-append, [L.list: "mis", "mal"], [L.list: "fortune"])
    is [L.list: "misfortune"]
  L.map2(string-append, [L.list: "mis", "mal"], L.empty)
    is L.empty
end
    }
 
  ◊function["map3"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" "b" "c" "d"))
    (a-var-type "l1" (L-of "a"))
    (a-var-type "l2" (L-of "b"))
    (a-var-type "l3" (L-of "c"))
    (L-of "d"))

  ]

When the ◊pyret{List}s are of different length, the function is only
called when all ◊pyret{List}s have a value at a given index.  In other words,
Pyret iterates over the shortest ◊pyret{List} and stops.

◊examples[#:show-try-it #t]{
import lists as L

check:
  fun full-name(n1, n2, n3) -> String:
    n1 + " " + n2 + " " + n3
  end
  full-name("Thomas", "Alva", "Edison") is "Thomas Alva Edison"
  L.map3(full-name, [L.list: "Martin", "Mohandas", "Pelé"], 
    [L.list: "Luther", "Karamchand"], [L.list: "King", "Gandhi"]) is
  [L.list: "Martin Luther King", "Mohandas Karamchand Gandhi"]
end
}
  ◊function["map4"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" "b" "c" "d" "e"))
    (a-var-type "l1" (L-of "a"))
    (a-var-type "l2" (L-of "b"))
    (a-var-type "l3" (L-of "c"))
    (a-var-type "l4" (L-of "d"))
    (L-of "e"))
]

When the ◊pyret{List}s are of different length, the function is only
called when all ◊pyret{List}s have a value at a given index.  In other words,
Pyret iterates over the shortest ◊pyret{List} and stops.

◊examples[#:show-try-it #t]{
import lists as L

check:
  fun title-name(title, n1, n2, n3) -> String:
    title + " " + n1 + " " + n2 + " " + n3
  end
  L.map4(title-name, [L.list: "Reverend", "Mahātmā"], 
    [L.list: "Martin", "Mohandas", "Pele"], 
    [L.list: "Luther", "Karamchand"], [list: "King", "Gandhi"]) is
  [L.list: "Reverend Martin Luther King", "Mahātmā Mohandas Karamchand Gandhi"]
end
}
  ◊function["map_n"
    #:contract
    (a-ftype
      (a-var-type "f" (a-ftype N "a" "b"))
      (a-var-type "n" N)
      (a-var-type "lst" (L-of "a"))
      (L-of "b"))
  ]

  Like map, but also includes a numeric argument for the position in the ◊pyret{List}
  that is currently being mapped over.

  ◊examples[#:show-try-it #t]{
import lists as L

check:
  L.map_n(num-expt, 0, [L.list: 2, 2, 2, 2]) is [L.list: 0, 1, 4, 9]
  L.map_n(lam(n, elem): n * elem end, 0, [L.list: 2, 2, 2, 2]) is [L.list: 0, 2, 4, 6]
  L.map_n(_ * _, 0, [L.list: 2, 2, 2, 2]) is [L.list: 0, 2, 4, 6]
  L.map_n(_ * _, 1, [L.list: 2, 2, 2, 2]) is [L.list: 2, 4, 6, 8]
  L.map_n(_ + _, 10, [L.list: 2, 2, 2, 2]) is [L.list: 12, 13, 14, 15]
end
  }

  ◊function["map2_n"
    #:contract
    (a-ftype
      (a-var-type "f" (a-ftype N "a" "b" "c"))
      (a-var-type "n" N)
      (a-var-type "lst" (L-of "a"))
      (a-var-type "lst" (L-of "b"))
      (L-of "c"))
  ]

Like ◊pyret-id{map_n}, but for two-argument functions.

When the ◊pyret{List}s are of different length, the function is only
called when all ◊pyret{List}s have a value at a given index.  In other words,
Pyret iterates over the shortest ◊pyret{List} and stops.
  
◊examples[#:show-try-it #t]{
import lists as L

check:
  L.map2_n(lam(n, a, b): n * (a + b) end, 10,
    [L.list: 2, 2, 2, 2], [L.list: 0, 3, 9, 12]) 
    is [L.list: 20, 55, 132, 182]
end
 }


  ◊function["map3_n"
    #:contract
    (a-ftype
      (a-var-type "f" (a-ftype N "a" "b" "c" "d"))
      (a-var-type "n" N)
      (a-var-type "lst" (L-of "a"))
      (a-var-type "lst" (L-of "b"))
      (a-var-type "lst" (L-of "c"))
      (L-of "d"))
  ]

When the ◊pyret{List}s are of different length, the function is only
called when all ◊pyret{List}s have a value at a given index.  In other words,
Pyret iterates over the shortest ◊pyret{List} and stops.

◊examples[#:show-try-it #t]{
import lists as L

check:
  fun combine(n, l1, l2, l3) -> String:
    string-repeat(l1, n) + string-repeat(l2, n) +
    string-repeat(l3, n)
  end
  combine(2, 'a', 'b', 'c') is "aabbcc"
  L.map3_n(combine, 1, [L.list: 'a', 'a'], [L.list: 'b', 'b'],
    [L.list: 'c', 'c']) is [L.list: 'abc', 'aabbcc']
end
}
  ◊function["map4_n"
    #:contract
    (a-ftype
      (a-var-type "f" (a-ftype N "a" "b" "c" "d" "e"))
      (a-var-type "n" N)
      (a-var-type "lst" (L-of "a"))
      (a-var-type "lst" (L-of "b"))
      (a-var-type "lst" (L-of "c"))
      (a-var-type "lst" (L-of "d"))
      (L-of "e"))
  ]

◊examples[#:show-try-it #t]{
import lists as L

check:
  fun combine(n, l1, l2, l3, l4) -> String:
    string-repeat(l1, n) + string-repeat(l2, n) +
    string-repeat(l3, n) + string-repeat(l4, n)
  end
  combine(2, 'a', 'b', 'c', 'd') is "aabbccdd"
  L.map4_n(combine, 1, L.repeat(3, 'a'), L.repeat(3, 'b'),
    L.repeat(3, 'c'), L.repeat(3, 'd')) is 
  [L.list: 'abcd', 'aabbccdd', 'aaabbbcccddd']
end
}

  ◊function[
    "each"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" No))
    (a-var-type "lst" (L-of "a"))
    No)
  ]
    ◊examples{
import lists as L

check:
  one-four = [list: 1, 2, 3, 4]
  block:
    var counter = 0
    L.each(lam(n): counter := counter + n end, one-four)
    counter is 1 + 2 + 3 + 4
    counter is 10
  end
  block:
    var counter = 1
    L.each(lam(n): counter := counter * n end, one-four)
    counter is 1 * 2 * 3 * 4
    counter is 24
  end
end
    }


  ◊function["each2"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" "b" No))
    (a-var-type "lst" (L-of "a"))
    (a-var-type "lst" (L-of "b"))
    No)
]
◊examples[#:show-try-it #t]{
import lists as L

check:
  var counter = 0
  L.each2(lam(x, y): counter := counter + x + y end, 
    [L.list: 1, 1, 1], [L.list: 10, 10, 10, 10])
  counter is 33
end
}
  
  ◊function["each3"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" "b" "c" No))
    (a-var-type "lst" (L-of "a"))
    (a-var-type "lst" (L-of "b"))
    (a-var-type "lst" (L-of "c"))
    No)
]
◊examples[#:show-try-it #t]{
import lists as L

check:
  var counter = 0
  L.each3(lam(x, y, z): counter := counter + x + y + z end, 
    [L.list: 1, 1, 1], [L.list: 10, 10, 10, 10], [L.list: 100, 100])
  counter is 222
end
}
  ◊function["each4"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "a" "b" "c" "d" No))
    (a-var-type "lst" (L-of "a"))
    (a-var-type "lst" (L-of "b"))
    (a-var-type "lst" (L-of "c"))
    (a-var-type "lst" (L-of "d"))
    No)
]
◊examples[#:show-try-it #t]{
import lists as L

check:
  var counter = 0
  L.each4(lam(w, x, y, z): counter := counter + w + x + y + z end,
    [L.list: 1, 1, 1], 
    [L.list: 10, 10, 10, 10], 
    [L.list: 100, 100], 
    [L.list: 1000, 1000])
  counter is 2222
end
}

  ◊function["each_n"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype N "a" No))
    (a-var-type "num" N)
    (a-var-type "lst" (L-of "a"))
    No
  )
  ]

Like ◊pyret-id{each}, but also includes a numeric argument for
the current index in the ◊pyret{List}.

◊examples[#:show-try-it #t]{
import lists as L

check:
  var counter = 0
  L.each_n(lam(i, w): counter := counter + (i * w) end, 
    1, 
    [L.list: 1, 1, 1])
  counter is 6
end
}

  ◊function["each2_n"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype N "a" "b" No))
    (a-var-type "num" N)
    (a-var-type "lst1" (L-of "a"))
    (a-var-type "lst2" (L-of "b"))
    No
  )
]
◊examples[#:show-try-it #t]{
import lists as L

check:
  var counter = 0
  L.each2_n(lam(i, w, x): counter := counter + (i * (w + x)) end,
    1,
    [L.list: 1, 1, 1],
    [L.list: 10, 10, 10, 10])
  counter is 66
end
}

  ◊function["each3_n"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype N "a" "b" "c" No))
    (a-var-type "num" N)
    (a-var-type "lst1" (L-of "a"))
    (a-var-type "lst2" (L-of "b"))
    (a-var-type "lst3" (L-of "c"))
    No
  )
]
◊examples[#:show-try-it #t]{
import lists as L

check:
  var counter = 0
  L.each3_n(lam(i, w, x, y): counter := counter + (i * (w + x + y)) end,
    1,
    [L.list: 1, 1, 1],
    [L.list: 10, 10, 10, 10],
    [L.list: 100, 100, 100])
  counter is 666
end
}
  ◊function["each4_n"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype N "a" "b" "c" "d" No))
    (a-var-type "num" N)
    (a-var-type "lst1" (L-of "a"))
    (a-var-type "lst2" (L-of "b"))
    (a-var-type "lst3" (L-of "c"))
    (a-var-type "lst4" (L-of "d"))
    No
  )
]
◊examples[#:show-try-it #t]{
import lists as L

check:
  var counter = 0
  L.each4_n(lam(i, w, x, y, z): counter := counter + (i * (w + x + y + z)) end,
    1,
    [L.list: 1, 1, 1],
    [L.list: 10, 10, 10, 10],
    [L.list: 100, 100, 100],
    [L.list: 1000, 1000, 1000])
  counter is 6666
end
}
  ◊function["fold-while"
    #:contract (a-ftype
    (a-var-type "f" (a-ftype "Base" "Elt" (E-of "Base" "Base")))
    (a-var-type "base" "Base")
    (a-var-type "lst" (L-of "Elt"))
    "Base"
  )
  ]

◊examples[#:show-try-it #t]{
import lists as L
import either as EI

check:
  fun stop-at-not-one(acc :: Number, n :: Number) -> EI.Either:
    if n == 1:  
      EI.left(acc + n)
    else: 
      EI.right(acc) 
    end
  end

  L.fold-while(stop-at-not-one, 0, [L.list: 1, 1, 1, 0, 1, 1]) is 3
end
}

  ◊function[
    "fold"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "Base" "Elt" "Base"))
    (a-var-type "base" "Base")
    (a-var-type "lst" (L-of "Elt"))
    "Base")
  ]{

◊pyret{fold} computes ◊pyret{f(... f(f(base, first-elt), second-elt) ..., last-elt)}.  For
◊pyret-id{empty}, returns ◊pyret{base}.

In other words, ◊pyret{fold} uses the function ◊tt{f}, starting with the ◊tt{base}
value, of type ◊tt{Base}, to calculate the return value of type ◊tt{Base} from each
item in the ◊pyret{List}, of input type ◊tt{Elt}, starting the sequence from the left.
  }
◊examples[#:show-try-it #t]{
import lists as L

check:
  L.fold((lam(acc, elt): acc + elt end), 0, [L.list: 3, 2, 1]) is 6
  L.fold((lam(acc, elt): acc + elt end), 10, [L.list: 3, 2, 1]) is 16

  fun combine(acc, elt) -> String:
    tostring(elt) + " - " + acc
  end
  L.fold(combine, "END", [L.list: 3, 2, 1]) is "1 - 2 - 3 - END"
  L.fold(combine, "END", L.empty) is "END"
end
 }
  ◊function["foldl"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "Base" "Elt" "Base"))
    (a-var-type "base" "Base")
    (a-var-type "lst" (L-of "Elt"))
    "Base")
  ]
  Another name for ◊pyret-id["fold"].
  ◊function["foldr"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "Base" "Elt" "Base"))
    (a-var-type "base" "Base")
    (a-var-type "lst" (L-of "Elt"))
    "Base")
  ]
Computes ◊pyret{f(f(... f(base, last-elt) ..., second-elt), first-elt)}.  For
◊pyret-id{empty}, returns ◊pyret{base}.  In other words, it uses
◊pyret{f} to combine ◊pyret{base} with each item in the ◊pyret{List} starting from the right.

In other words, ◊pyret{foldr} uses the function ◊tt{f}, starting with the ◊tt{base}
value, of type ◊tt{Base}, to calculate the return value of type ◊tt{Base} from each
item in the ◊pyret{List}, of input type ◊tt{Elt}, starting the sequence from the right.

◊examples[#:show-try-it #t]{
import lists as L

check:
  L.foldr((lam(acc, elt): acc + elt end), 0, [L.list: 3, 2, 1]) is 6
  L.foldr((lam(acc, elt): acc + elt end), 10, [L.list: 3, 2, 1]) is 16

  fun combine(acc, elt) -> String:
    tostring(elt) + " - " + acc
  end
  L.foldr(combine, "END", [L.list: 3, 2, 1]) is "3 - 2 - 1 - END"
  L.foldr(combine, "END", L.empty) is "END"
end
}

  ◊function["fold2"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "Base" "Elt1" "Elt2" "Base"))
    (a-var-type "base" "Base")
    (a-var-type "l1" (L-of "Elt1"))
    (a-var-type "l2" (L-of "Elt2"))
    "Base")
]

◊examples[#:show-try-it #t]{
import lists as L

check:
  L.fold2(lam(acc, elt1, elt2): acc + elt1 + elt2 end,
    11,
    [L.list: 1, 1, 1],
    [L.list: 10, 10, 10, 10])
    is 44
end
}

  ◊function["fold3"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "Base" "Elt1" "Elt2" "Elt3" "Base"))
    (a-var-type "base" "Base")
    (a-var-type "l1" (L-of "Elt1"))
    (a-var-type "l2" (L-of "Elt2"))
    (a-var-type "l3" (L-of "Elt3"))
    "Base")
]
◊examples[#:show-try-it #t]{
import lists as L

check:
  fold3(lam(acc, elt1, elt2, elt3): acc + elt1 + elt2 + elt3 end, 
    111,
    [L.list: 1, 1, 1],
    [L.list: 10, 10, 10, 10], 
    [L.list: 100, 100, 100])
    is 444
end
}


  ◊function["fold4"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype "Base" "Elt1" "Elt2" "Elt3" "Elt4" "Base"))
    (a-var-type "base" "Base")
    (a-var-type "l1" (L-of "Elt1"))
    (a-var-type "l2" (L-of "Elt2"))
    (a-var-type "l3" (L-of "Elt3"))
    (a-var-type "l4" (L-of "Elt4"))
    "Base")
]
◊examples[#:show-try-it #t]{
import lists as L

check:
  L.fold4(lam(acc, elt1, elt2, elt3, elt4): 
    acc + elt1 + elt2 + elt3 + elt4 end,
    1111, 
    [L.list: 1, 1, 1],
    [L.list: 10, 10, 10, 10],
    [L.list: 100, 100, 100],
    [list: 1000, 1000])
    is 3333
end
}

  ◊function[
    "fold_n"
    #:contract (a-ftype
    (a-var-type "f" (p-a-ftype N "Base" "Elt" "Base"))
        (a-var-type "num" N)
        (a-var-type "base" "Base")
        (a-var-type "lst" (L-of "Elt"))
    "Base")
  ]
    ◊examples{
import lists as L

check:
  # for comparison, here is a map_n example:
  L.map_n(lam(index, elt): index * elt end, 0, [L.list: 2, 2, 2, 2]) 
    is [L.list: 0, 2, 4, 6]
  # this fold_n version adds up the result
  L.fold_n(lam(index, acc, elt): acc + (index * elt) end, 0, 0,
    [L.list: 2, 2, 2, 2])
    is 12
  L.fold_n(lam(index, acc, elt): acc + (index * elt) end, 0, 10,
    [L.list: 2, 2, 2, 2])
    is 22
  L.fold_n(lam(index, acc, elt): acc + (index * elt) end, 10, 0,
    [L.list: 2, 2, 2, 2])
    is 92 because 20 + 22 + 24 + 26
end
    }
  {

  Like ◊pyret-id{fold}, but takes a numeric argument for the position in the
  ◊pyret{List} that is currently being visited.

  }

  ◊function[
    "member"
    #:contract (a-ftype
    (a-var-type "lst" (L-of "a"))
    (a-var-type "elt" "a")
    B)
  ]

◊function["member-always"
    #:contract (a-ftype
    (a-var-type "lst" (L-of "a"))
    (a-var-type "elt" "a")
    B)
]
◊function["member-identical"
    #:contract (a-ftype
    (a-var-type "lst" (L-of "a"))
    (a-var-type "elt" "a")
    B)
]
◊function["member-now"
    #:contract (a-ftype
    (a-var-type "lst" (L-of "a"))
    (a-var-type "elt" "a")
    B)
]

◊pyret{member}
returns ◊pyret{true} if ◊pyret{List} ◊tt{lst} contains the element ◊tt{elt}, as compared
by ◊pyret{==}.
The other three functions are
analogous to ◊pyret-id{member}, but use
◊pyret-id["equal-always" "equality"],
◊pyret-id["identical" "equality"], or
◊pyret-id["equal-now" "equality"]
to perform the comparison.
(Thus ◊pyret{member-always} is the same as ◊pyret{member}; the name is provided for completeness
and in case the user wants to make their intent more explicit.)

Note that if a ◊pyret{Roughnum} is present, these functions will raise exceptions. To avoid that, use
◊pyret-id["member3" "lists"] and the analogous related functions.

◊examples[#:show-try-it #t]{
import lists as L

check:
  L.member([L.list: 1, 2, 3], 2) is true
  L.member([L.list: 2, 4, 6], 3) is false
  L.member([L.list: ], L.empty) is false
  L.member([L.list: 1, 2, 3], ~1) raises "Roughnums"
  L.member([L.list: ~1, 2, 3], 1) raises "Roughnums"

  L.member([L.list: 'a'], 'a') is true
  L.member([L.list: false], false) is true
  L.member([L.list: nothing], nothing) is true
end
}

◊function["member3"
#:contract (a-ftype
(a-var-type "lst" (L-of "a"))
(a-var-type "elt" "a")
"EqualityResult"
)
]
◊function["member-always3"
#:contract (a-ftype
(a-var-type "lst" (L-of "a"))
(a-var-type "elt" "a")
"EqualityResult"
)
]
◊function["member-identical3"
#:contract (a-ftype
(a-var-type "lst" (L-of "a"))
(a-var-type "elt" "a")
"EqualityResult"
)
]
◊function["member-now3"
#:contract (a-ftype
(a-var-type "lst" (L-of "a"))
(a-var-type "elt" "a")
"EqualityResult"
)
]

These functions are analogous to ◊pyret-id{member}, but use
◊pyret-id["equal-always3" "equality"],
◊pyret-id["identical3" "equality"], or
◊pyret-id["equal-now3" "equality"]
to perform the comparison. Thus, they do not raise an exception if a ◊pyret{Roughnum} is present.

◊examples[#:show-try-it #t]{
import lists as L
import equality as EQ

check:
  L.member3([L.list: 1, 2, 3], ~1) satisfies EQ.is-Unknown
  L.member3([L.list: ~1, 2, 3], 1) satisfies EQ.is-Unknown
end
}

◊function[
    "member-with"
    #:contract (a-ftype
    (a-var-type "lst" (L-of "a"))
    (a-var-type "elt" "a")
    (a-var-type "eq" (p-a-ftype "a" "a" "EqualityResult"))
    "EqualityResult"
    )
  ]

◊pyret{member-with} is ◊pyret{member} with a custom equality function.
Returns an ◊pyret{equality.Equal} if
the ◊tt{eq} parameter returns ◊pyret{equality.Equal} for ◊tt{elt} and any one
element of ◊pyret{List} ◊tt{lst}.

◊examples[#:show-try-it #t]{
import lists as L
import equality as EQ

check:
  fun equal-length(a :: String, b :: String) -> EQ.EqualityResult:
    if string-length(a) == string-length(b):
      EQ.Equal
    else:
      EQ.NotEqual("Different lengths.", a, b)
    end
  end
  equal-length('tom', 'dad') is EQ.Equal
  equal-length('tom', 'father') satisfies EQ.is-NotEqual

  L.member-with([L.list: 'father', 'pater', 'dad'], 'tom', equal-length)
    is EQ.Equal
  L.member-with([L.list: 'father', 'pater'], 'tom', equal-length) 
    satisfies EQ.is-NotEqual 
end
}

  ◊function[
    "reverse"
    #:contract (a-ftype
    (a-var-type "lst" (L-of "a"))
    (L-of "a")
    )
  ]

Returns a new ◊pyret{List} with all the elements of the original ◊pyret{List} in
reverse order.

◊examples[#:show-try-it #t]{
import lists as L

check:
  l = [L.list: 1, 2, 3, 4]
  L.reverse(l) is [L.list: 4, 3, 2, 1]
end
}

◊function["remove"
#:contract (a-ftype
(a-var-type "lst" (L-of "a"))
(a-var-type "elt" "a")
(L-of "a")
)
]
Returns a new ◊pyret{List} with all the elements of the original that are not
equal to the specified element (using ◊pyret-id["==" "equality"] as the comparison).

◊examples[#:show-try-it #t]{
import lists as L

check:
  l = [L.list: 1, 2, 3, 4, 3, 2, 1]
  L.remove(l, 2) is [L.list: 1, 3, 4, 3, 1]
end
}


  ◊function[
    "shuffle"
    #:contract (a-ftype
    (a-var-type "lst" (L-of "a"))
    (L-of "a"))
  ]

  Returns a new ◊pyret{List} with all the elements of the original ◊pyret{List} in random
  order.

◊examples[#:show-try-it #t]{
import lists as L
import sets as S

check:
  l = [L.list: 1, 2, 3, 4]                                  
  l-mixed = L.shuffle(l)
  S.list-to-set(l-mixed) is S.list-to-set(l)                   
  l-mixed.length() is l.length()  
end
}

}

