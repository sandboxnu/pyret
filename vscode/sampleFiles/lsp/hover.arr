use context empty-context

x :: Number
x = 17

y :: Number = 38

fun not-zero(n :: Number) -> Boolean:
  doc: ```answers "is n nonzero?"```
  n <> 0
end

not-zero

div-refine :: Number, Number%(not-zero) -> Number
fun div-refine(num, den):
  doc: "divides the things"
  num / den
end

div-refine

fun destruct-some-anns({a; b}, {c :: Number; d :: Number}):
  a + b + c + d
end

destruct-some-anns

fun tup-anns(t :: {Number; Number}, r :: {a :: Number, b :: Number}):
  t.{0} + r.a
end

tup-anns

div2 :: ((n :: Number, m :: Number) -> Boolean) = div-refine
div2

g = lam(n :: Number) -> Boolean: not-zero(n) end
g

g-ann :: Any = lam(n :: Number) -> Boolean: not-zero(n) end
g-ann
