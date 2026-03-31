#lang pollen

◊(define s-some-args (list `("value" ("type" "normal") ("contract" ,(a-id "a")))))


◊docmodule["option"]{
  ◊; Ignored type testers
  ◊section{The Option Datatype}

  ◊data-spec2["Option" (list "a") (list
    ◊singleton-spec2["Option" "none"]
    ◊constructor-spec["Option" "some" s-some-args]
  )]

  ◊nested[#:style 'inset]{
  ◊singleton-doc["Option" "none" (O-of "a")]
  ◊constructor-doc["Option" "some" s-some-args (O-of "a")]

  ◊function["is-none" #:contract (a-arrow (p-a-var-type "val" A) B)]
  ◊function["is-some" #:contract (a-arrow (p-a-var-type "val" A) B)]
  }

◊pyret{Option} implements a functional programming idiom that is often used
when a function may or may not return a valid or meaningful value.  If there
is no return value, the function returns ◊pyret{none}.  If there is a meaningful
return value, it returns that value wrapped in the ◊pyret{some} variant.

Some Pyret library functions return ◊pyret{Option} values, such as
◊pyret{string-to-number}.  When the string is not a
valid numeric value, it returns ◊pyret{none}; otherwise, it
returns the numeric value wrapped in ◊pyret{some}.  A ◊pyret{cases} expression
can be used to evaluate both ◊pyret{Option} response variants.


◊examples{ 
fun set-angle(s :: String) -> Number:
  doc: "If s is not a numeric string, default to 0."
  cases(Option) string-to-number(s):
    | some(a) => a
    | none => 0
  end
where:
  set-angle("90") is 90
  set-angle("") is 0
  set-angle("x") is 0
end
}

In contrast, ◊pyret{string-index-of} does
◊italic{not} return an ◊pyret{Option} return value.Instead , it returns a
◊pyret{Number} that is either a valid index ◊pyret{Number} or
◊tt{-1} if the string is not found:

◊examples{
fun find-smiley(s :: String) -> String:
  i = string-index-of(s, "😊")
  ask:
    | i == -1 then: "No smiley!"
    | otherwise: string-append("Smiley at ", num-to-string(i))
  end
where:
  find-smiley("abcd") is "No smiley!"
  find-smiley("a😊cd") is "Smiley at 1"
end
}

We can create a version of ◊tt{find-smiley} that returns an
◊pyret{Option} value, such as this:

◊examples{
fun option-smiley(s :: String) -> Option<Number>:
  i = string-index-of(s, "😊")
  ask:
    | i == -1 then: none
    | otherwise: some(i)
  end
where:
  option-smiley("abcd") is none
  option-smiley("a😊cd") is some(1)
end
}

◊section{Option Methods}
  ◊method-doc["Option" "some" "and-then"
     #:contract (a-arrow (p-a-var-type "f" (p-a-var-type "a" "b")) (O-of "b")) ]

  For ◊pyret-id{none}, returns ◊pyret-id{none}.  For ◊pyret-id{some}, applies
  ◊pyret{f} to the ◊pyret{value} field and returns a new ◊pyret-id{some} with the
  updated value.

◊examples{
check:
  add1 = lam(n): n + 1 end
  n = none
  n.and-then(add1) is none
  s = some(5)
  s.and-then(add1) is some(6)
end
}

  ◊method-doc["Option" "some" "or-else"
    #:contract (a-arrow (p-a-var-type "v" "a") "a") ]

  For ◊pyret-id{none}, returns ◊pyret{v}.  For ◊pyret-id{some}, returns the
  ◊pyret{value} field.  Useful for providing default values.

◊examples{
check:
  n = none
  n.or-else(42) is 42
  
  s = some(5)
  s.or-else(10) is 5
end
}

Therefore, our example above of ◊tt{set-angle}, which defaults to ◊tt{0}, could be
written this way:

◊examples{
fun set-angle(s :: String) -> Number:
  doc: "If s is not a numeric string, default to 0."
  string-to-number(s).or-else(0)
where:
  set-angle("90") is 90
  set-angle("") is 0
  set-angle("x") is 0
end
}
  }
