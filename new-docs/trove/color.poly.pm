#lang pollen

◊(define (make-paint-swatch name css-color)
  ◊; (printf "*** make-paint-swatch ~a ~a \n" name css-color)
  `(span ([style "font-size: initial"])
         (img ([class "paintBrush"] [src "brush.svg"]))
         (span ([class "paintSpan"])
               (span ([class "checkersBlob"]
                      [style ,(format "background-color: ~a;" css-color)]))
               (span ([style ,(format "background-color: ~a; margin-right: 0.25em"
               css-color)]
                      [class "paintBlob"])))))

◊(define (left-zero-pad s n)
  (let ([m (string-length s)])
    (if (< m n)
        (string-append (make-string (- n m) #\0) s)
        s)))

◊(define (dec-to-2-digit-hex a)
  (left-zero-pad (number->string a 16) 2))

◊(define (make-fg-element r g b)
  `(span ([style ,(format "color: #~a~a~a"
                   (dec-to-2-digit-hex r) (dec-to-2-digit-hex g) (dec-to-2-digit-hex b))])
         "abc123"))

◊(define (make-bg-element r g b)
  `(span ([style ,(format "background-color: #~a~a~a"
                   (dec-to-2-digit-hex r) (dec-to-2-digit-hex g) (dec-to-2-digit-hex b))])
         "abc123"))

◊(define (render-color name r g b a)
   (define css-color (format "rgba(~a,~a,~a,~a)" r g b a))
◊; (printf "*** render-color ~a ~a ~a ~a ~a\n" name r g b a)
         `(li ()
           ,(make-paint-swatch name css-color)
           ,name
           ": "
           ,(make-fg-element r g b)
           ,(make-bg-element r g b)))


◊(define number (a-id "Number" (xref "<global>" "Number")))
◊(define color-args (list
      `("red"   ("type" "normal") ("contract" ,number))
      `("green" ("type" "normal") ("contract" ,number))
      `("blue"  ("type" "normal") ("contract" ,number))
      `("alpha" ("type" "normal") ("contract" ,number))))

◊docmodule["color"]{
  ◊; Ignored type testers
  ◊ignore[(list "is-color")]
  ◊emph{◊bold{Note:}} it is discouraged to use the ◊pyret{include} form of importing this library,
  since this library defines many names, some of which will likely conflict with existing names.
  (For instance, ◊pyret{tan} is both a color and a mathematical function.)  Use the ◊pyret{import}
  form instead. See ◊secref["s:modules:import"] for more detail.

  ◊section[#:tag "color_DataTypes"]{Data types}
  ◊data-spec2["Color" (list) (list
    ◊constructor-spec["Color" "color" color-args]
  )]
  ◊nested[#:style 'inset]{
    ◊constructor-doc["Color" "color" color-args (a-id "Color" (xref "color" "Color"))]{
      The values for red, green, and blue should be in the range 0--255, inclusive.
      The values for alpha should be in the range 0--1, and indicates how transparent the color is, with 0 as fully transparent and 1 as fully opaque.

      Note that the library does not ◊emph{enforce} these range restrictions when constructing custom colors, so that you can manipulate colors arithmetically (e.g. modeling ``additive color'' by literally adding components together).  The ◊emph{rendering} of these colors will clamp the values into those ranges, so e.g. ◊pyret{color(500, 255, 0, 1)} will look the same as ◊pyret{yellow} itself, but the values will not be equal.
    }
  }

  ◊section[#:tag "s:color-constants"]{Predefined colors}
  The following colors are predefined constants:
  ◊itemlist[
    ◊render-color["orange" 255 165 0 1]
    ◊render-color["red" 255 0 0 1]
    ◊render-color["orange-red" 255 69 0 1]
    ◊render-color["tomato" 255 99 71 1]
    ◊render-color["dark-red" 139 0 0 1]
    ◊render-color["fire-brick" 178 34 34 1]
    ◊render-color["crimson" 220 20 60 1]
    ◊render-color["deep-pink" 255 20 147 1]
    ◊render-color["maroon" 176 48 96 1]
    ◊render-color["indian-red" 205 92 92 1]
    ◊render-color["medium-violet-red" 199 21 133 1]
    ◊render-color["violet-red" 208 32 144 1]
    ◊render-color["light-coral" 240 128 128 1]
    ◊render-color["hot-pink" 255 105 180 1]
    ◊render-color["pale-violet-red" 219 112 147 1]
    ◊render-color["light-pink" 255 182 193 1]
    ◊render-color["rosy-brown" 188 143 143 1]
    ◊render-color["pink" 255 192 203 1]
    ◊render-color["orchid" 218 112 214 1]
    ◊render-color["lavender-blush" 255 240 245 1]
    ◊render-color["snow" 255 250 250 1]
    ◊render-color["chocolate" 210 105 30 1]
    ◊render-color["saddle-brown" 139 69 19 1]
    ◊render-color["brown" 132 60 36 1]
    ◊render-color["dark-orange" 255 140 0 1]
    ◊render-color["coral" 255 127 80 1]
    ◊render-color["sienna" 160 82 45 1]
    ◊render-color["salmon" 250 128 114 1]
    ◊render-color["peru" 205 133 63 1]
    ◊render-color["dark-goldenrod" 184 134 11 1]
    ◊render-color["goldenrod" 218 165 32 1]
    ◊render-color["sandy-brown" 244 164 96 1]
    ◊render-color["light-salmon" 255 160 122 1]
    ◊render-color["dark-salmon" 233 150 122 1]
    ◊render-color["gold" 255 215 0 1]
    ◊render-color["yellow" 255 255 0 1]
    ◊render-color["olive" 128 128 0 1]
    ◊render-color["burlywood" 222 184 135 1]
    ◊render-color["tan" 210 180 140 1]
    ◊render-color["navajo-white" 255 222 173 1]
    ◊render-color["peach-puff" 255 218 185 1]
    ◊render-color["khaki" 240 230 140 1]
    ◊render-color["dark-khaki" 189 183 107 1]
    ◊render-color["moccasin" 255 228 181 1]
    ◊render-color["wheat" 245 222 179 1]
    ◊render-color["bisque" 255 228 196 1]
    ◊render-color["pale-goldenrod" 238 232 170 1]
    ◊render-color["blanched-almond" 255 235 205 1]
    ◊render-color["medium-goldenrod" 234 234 173 1]
    ◊render-color["papaya-whip" 255 239 213 1]
    ◊render-color["misty-rose" 255 228 225 1]
    ◊render-color["lemon-chiffon" 255 250 205 1]
    ◊render-color["antique-white" 250 235 215 1]
    ◊render-color["cornsilk" 255 248 220 1]
    ◊render-color["light-goldenrod-yellow" 250 250 210 1]
    ◊render-color["old-lace" 253 245 230 1]
    ◊render-color["linen" 250 240 230 1]
    ◊render-color["light-yellow" 255 255 224 1]
    ◊render-color["seashell" 255 245 238 1]
    ◊render-color["beige" 245 245 220 1]
    ◊render-color["floral-white" 255 250 240 1]
    ◊render-color["ivory" 255 255 240 1]
    ◊render-color["green" 0 255 0 1]
    ◊render-color["lawn-green" 124 252 0 1]
    ◊render-color["chartreuse" 127 255 0 1]
    ◊render-color["green-yellow" 173 255 47 1]
    ◊render-color["yellow-green" 154 205 50 1]
    ◊render-color["medium-forest-green" 107 142 35 1]
    ◊render-color["olive-drab" 107 142 35 1]
    ◊render-color["dark-olive-green" 85 107 47 1]
    ◊render-color["dark-sea-green" 143 188 139 1]
    ◊render-color["lime" 0 255 0 1]
    ◊render-color["dark-green" 0 100 0 1]
    ◊render-color["lime-green" 50 205 50 1]
    ◊render-color["forest-green" 34 139 34 1]
    ◊render-color["spring-green" 0 255 127 1]
    ◊render-color["medium-spring-green" 0 250 154 1]
    ◊render-color["sea-green" 46 139 87 1]
    ◊render-color["medium-sea-green" 60 179 113 1]
    ◊render-color["aquamarine" 112 216 144 1]
    ◊render-color["light-green" 144 238 144 1]
    ◊render-color["pale-green" 152 251 152 1]
    ◊render-color["medium-aquamarine" 102 205 170 1]
    ◊render-color["turquoise" 64 224 208 1]
    ◊render-color["light-sea-green" 32 178 170 1]
    ◊render-color["medium-turquoise" 72 209 204 1]
    ◊render-color["honeydew" 240 255 240 1]
    ◊render-color["mint-cream" 245 255 250 1]
    ◊render-color["royal-blue" 65 105 225 1]
    ◊render-color["dodger-blue" 30 144 255 1]
    ◊render-color["deep-sky-blue" 0 191 255 1]
    ◊render-color["cornflower-blue" 100 149 237 1]
    ◊render-color["steel-blue" 70 130 180 1]
    ◊render-color["light-sky-blue" 135 206 250 1]
    ◊render-color["dark-turquoise" 0 206 209 1]
    ◊render-color["cyan" 0 255 255 1]
    ◊render-color["aqua" 0 255 255 1]
    ◊render-color["dark-cyan" 0 139 139 1]
    ◊render-color["teal" 0 128 128 1]
    ◊render-color["sky-blue" 135 206 235 1]
    ◊render-color["cadet-blue" 95 158 160 1]
    ◊render-color["dark-slate-gray" 47 79 79 1]
    ◊render-color["dark-slate-grey" 47 79 79 1]
    ◊render-color["light-slate-gray" 119 136 153 1]
    ◊render-color["light-slate-grey" 119 136 153 1]
    ◊render-color["slate-gray" 112 128 144 1]
    ◊render-color["slate-grey" 112 128 144 1]
    ◊render-color["light-steel-blue" 176 196 222 1]
    ◊render-color["light-blue" 173 216 230 1]
    ◊render-color["powder-blue" 176 224 230 1]
    ◊render-color["pale-turquoise" 175 238 238 1]
    ◊render-color["light-cyan" 224 255 255 1]
    ◊render-color["alice-blue" 240 248 255 1]
    ◊render-color["azure" 240 255 255 1]
    ◊render-color["medium-blue" 0 0 205 1]
    ◊render-color["dark-blue" 0 0 139 1]
    ◊render-color["midnight-blue" 25 25 112 1]
    ◊render-color["navy" 36 36 140 1]
    ◊render-color["blue" 0 0 255 1]
    ◊render-color["indigo" 75 0 130 1]
    ◊render-color["blue-violet" 138 43 226 1]
    ◊render-color["medium-slate-blue" 123 104 238 1]
    ◊render-color["slate-blue" 106 90 205 1]
    ◊render-color["purple" 160 32 240 1]
    ◊render-color["dark-slate-blue" 72 61 139 1]
    ◊render-color["dark-violet" 148 0 211 1]
    ◊render-color["dark-orchid" 153 50 204 1]
    ◊render-color["medium-purple" 147 112 219 1]
    ◊render-color["medium-orchid" 186 85 211 1]
    ◊render-color["magenta" 255 0 255 1]
    ◊render-color["fuchsia" 255 0 255 1]
    ◊render-color["dark-magenta" 139 0 139 1]
    ◊render-color["violet" 238 130 238 1]
    ◊render-color["plum" 221 160 221 1]
    ◊render-color["lavender" 230 230 250 1]
    ◊render-color["rebecca-purple" 102 51 153 1]
    ◊render-color["thistle" 216 191 216 1]
    ◊render-color["ghost-white" 248 248 255 1]
    ◊render-color["white" 255 255 255 1]
    ◊render-color["white-smoke" 245 245 245 1]
    ◊render-color["gainsboro" 220 220 220 1]
    ◊render-color["light-gray" 211 211 211 1]
    ◊render-color["light-grey" 211 211 211 1]
    ◊render-color["silver" 192 192 192 1]
    ◊render-color["gray" 190 190 190 1]
    ◊render-color["grey" 190 190 190 1]
    ◊render-color["dark-gray" 169 169 169 1]
    ◊render-color["dark-grey" 169 169 169 1]
    ◊render-color["dim-gray" 105 105 105 1]
    ◊render-color["dim-grey" 105 105 105 1]
    ◊render-color["black" 0 0 0 1]
    ◊render-color["transparent" 0 0 0 0]
  ]
}
