
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

proc mix*(a, b: Color, ratio: float = 0.5): Color =
  var
    afactor = ratio
    bfactor = 1 - ratio
  result.r = (a.r.float * afactor + b.r.float * bfactor).uint8
  result.g = (a.g.float * afactor + b.g.float * bfactor).uint8
  result.b = (a.b.float * afactor + b.b.float * bfactor).uint8
  result.a = (a.a.float * afactor + b.a.float * bfactor).uint8

proc rf*(c: Color): float32 =
  if c.r == 1: 1.0
  else: c.r.float32 / 255.0
proc gf*(c: Color): float32 =
  if c.g == 1: 1.0
  else: c.g.float32 / 255.0
proc bf*(c: Color): float32 =
  if c.b == 1: 1.0
  else: c.b.float32 / 255.0
proc af*(c: Color): float32 =
  if c.a == 1: 1.0
  else: c.a.float32 / 255.0
