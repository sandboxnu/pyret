use context empty-context

x :: Number
x = 17

y :: Number = 38

fun not-zero(n :: Number) -> Boolean:
  doc: ```answers "is n nonzero?"```
  n <> 0
end

div-refine :: Number, Number%(not-zero) -> Number
fun div-refine(num, den):
  num / den
end

fun destruct-some-anns({a; b}, {c :: Number; d :: Number}):
  a + b + c + d
end

fun tup-anns(t :: {Number; Number}, r :: {a :: Number, b :: Number}):
  t.{0} + r.a
end

div2 :: ((n :: Number, m :: Number) -> Boolean) = div-refine
g = lam(n :: Number) -> Boolean: not-zero(n) end
g-ann :: Any = lam(n :: Number) -> Boolean: not-zero(n) end
