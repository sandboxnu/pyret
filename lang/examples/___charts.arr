include charts
include image
import color as C

fun some-fun(x): 1 / x end
a-series = from-list.function-plot(some-fun)
  .color(C.purple)

img = render-chart(a-series).get-image()
save-image(img, "chart.png")