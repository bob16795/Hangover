
type
  Color* = object
    r*: uint8
    g*: uint8
    b*: uint8
    a*: uint8

proc newColor*(r, g, b: uint8, a: uint8 = 255): Color =
  result.r = r
  result.g = g
  result.b = b
  result.a = a