#lang pollen

◊(define BR (a-id "Brand"))

◊docmodule["brands" #:friendly-title "Brands"]{

◊type-spec["Brand" (list "a")]{
Brands are a mostly internal language concept, useful for implementing custom datatypes.}

◊function["brander" #:contract (a-arrow (a-app BR (list "a")))]

Creates a new brand.

◊method-doc["Brand" "brander" "brand" #:alt-docstrings "" #:contract (a-arrow BR A "a")]

Produce a copy of the value with this brand.

◊method-doc["Brand" "brander" "test" #:alt-docstrings "" #:contract (a-arrow BR A B)]

Test if the value has this brand.

}
