#lang pollen


◊docmodule["booleans" #:noimport #t #:friendly-title "Booleans"]{

  ◊type-spec["Boolean"]{

  The type of the values ◊pyret{true} and ◊pyret{false}.}

  ◊section{Boolean Functions}

  ◊function["not" #:contract (a-ftype (a-var-type "b" B) B) #:return B #:alt-docstrings ""]

  Returns ◊pyret{true} when given ◊pyret{false} and vice versa.

◊examples{
check:
  not(true) is false
  not(2 < 1) is true
end
}
  ◊section{Boolean Operators}

◊form["and" "left and right"]{
  ◊margin-note{
  The ◊pyret{and} operator “short-circuits”: if ◊pyret{left}
  evaluates to ◊pyret{false}, then ◊pyret{right} is not evaluated at all and the
  result is ◊pyret{false}.
  }
  Expects ◊pyret{left} and ◊pyret{right} to be ◊pyret{Boolean}s.
  If both are
  ◊pyret{true}, the result is ◊pyret{true}, if either is ◊pyret{false}, the
  result is ◊pyret{false}.
  ◊examples[#:show-try-it #t]{
examples:
  true and true is true
  true and false is false
  false and true is false
  false and false is false
  (4 < 5) and ("a" == "b") is false
  (4 < 5) and ((4 + 2) == 6) is true
  (4 > 5) and ((4 + 2) == 6) is false
end
  }
}

◊form["or" "left or right"]{
  ◊margin-note{
  The ◊pyret{or} operator “short-circuits”: if ◊pyret{left}
  evaluates to ◊pyret{true}, then ◊pyret{right} is not evaluated at all and the
  result is ◊pyret{true}.
  }
  Expects ◊pyret{left} and ◊pyret{right} to be ◊pyret{Boolean}s.
  If either is
  ◊pyret{true}, the result is ◊pyret{true}, if both are ◊pyret{false}, the
  result is ◊pyret{false}.

  ◊examples[#:show-try-it #t]{
examples:
  true or true is true
  true or false is true
  false or true is true
  false or false is false
  (4 < 5) or ("a" == "b") is true
  (4 < 5) or ((4 + 2) == 6) is true
  (4 > 5) or ((4 + 2) == 6) is true
  (4 > 5) or ("a" == "b") is false
end
  }
}

}
