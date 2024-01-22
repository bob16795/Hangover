import strutils
import math

#TODO: comment

type
  Color* = object
    ## represents a color in rgba format
    r*: uint8
    g*: uint8
    b*: uint8
    a*: uint8

proc newColor*(r, g, b: uint8, a: uint8 = 255): Color =
  ## creates a new color
  result.r = r
  result.g = g
  result.b = b
  result.a = a

proc mix*(a, b: Color, ratio: float = 0.5): Color =
  ## mixes 2 colors
  let
    afactor = ratio
    bfactor = 1 - ratio
  result.r = (a.r.float * afactor + b.r.float * bfactor).uint8
  result.g = (a.g.float * afactor + b.g.float * bfactor).uint8
  result.b = (a.b.float * afactor + b.b.float * bfactor).uint8
  result.a = (a.a.float * afactor + b.a.float * bfactor).uint8

proc rf*(c: Color): float32 =
  c.r.float32 / 255.0

proc gf*(c: Color): float32 =
  c.g.float32 / 255.0

proc bf*(c: Color): float32 =
  c.b.float32 / 255.0

proc af*(c: Color): float32 =
  c.a.float32 / 255.0

proc `$`*(c: Color): string =
  result = "#"
  result &= c.r.toHex(2)
  result &= c.g.toHex(2)
  result &= c.b.toHex(2)
  result &= c.a.toHex(2)

proc hue*(c: Color): float32 =
  let
    r = c.rf
    g = c.gf
    b = c.bf
    mi = min(min(r, g), b)
    ma = max(max(r, g), b)
  if r > g and r > b:
    result = ((g - b) / (ma - mi)) / 6.0
  elif b > g:
    result = (4.0 + (r - g) / (ma - mi)) / 6.0
  else:
    result = (2.0 + (b - r) / (ma - mi)) / 6.0
  if result < 0:
    result += 1.0
  if result.classify == fcNaN:
    return 0.66
