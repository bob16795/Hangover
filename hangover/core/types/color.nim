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

proc rf*(c: Color): float32 =
  c.r.float32 / 255.0

proc gf*(c: Color): float32 =
  c.g.float32 / 255.0

proc bf*(c: Color): float32 =
  c.b.float32 / 255.0

proc af*(c: Color): float32 =
  c.a.float32 / 255.0

func sRGB(c: Color): Color =
  result.r = uint8(255 * clamp(if c.rf <= 0.0031308:
      c.rf * 12.92
    else:
      1.055 * pow(c.rf, 1 / 2.4) - 0.055, 0, 1))
  result.g = uint8(255 * clamp(if c.gf <= 0.0031308:
      c.gf * 12.92
    else:
      1.055 * pow(c.gf, 1 / 2.4) - 0.055, 0, 1))
  result.b = uint8(255 * clamp(if c.bf <= 0.0031308:
      c.bf * 12.92
    else:
      1.055 * pow(c.bf, 1 / 2.4) - 0.055, 0, 1))
  result.a = c.a

func linearRGB(c: Color): Color =
  result.r = uint8(255 * clamp(if c.rf <= 0.04045:
      c.rf / 12.9
    else:
      pow((c.rf + 0.055) / 1.055, 2.4), 0, 1))
  result.g = uint8(255 * clamp(if c.gf <= 0.04045:
      c.gf / 12.9
    else:
      pow((c.gf + 0.055) / 1.055, 2.4), 0, 1))
  result.b = uint8(255 * clamp(if c.bf <= 0.04045:
      c.bf / 12.9
    else:
      pow((c.bf + 0.055) / 1.055, 2.4), 0, 1))
  result.a = c.a

proc lerp*(a, b: Color, ratio: float): Color =
  ## mixes 2 colors
  let
    afactor = ratio
    bfactor = 1 - ratio
  result.r = (a.r.float * afactor + b.r.float * bfactor).uint8
  result.g = (a.g.float * afactor + b.g.float * bfactor).uint8
  result.b = (a.b.float * afactor + b.b.float * bfactor).uint8
  result.a = (a.a.float * afactor + b.a.float * bfactor).uint8

proc mix*(aLinear, bLinear: Color, ratio: float = 0.5): Color =

  ## mixes 2 colors
  let
    a = sRGB(aLinear)
    b = sRGB(bLinear)

  result = linearRGB(a.lerp(b, ratio))

proc `$`*(c: Color): string =
  result = "#"
  result &= c.r.toHex(2)
  result &= c.g.toHex(2)
  result &= c.b.toHex(2)
  result &= c.a.toHex(2)

proc newColorGray*(c: uint8): Color =
  return newColor(c, c, c, 255)

proc withAlpha*(c: Color, a: uint8): Color =
  return newColor(c.r, c.g, c.b, a)

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

proc parseColor*(s: string): Color =
  if s[0] == '#':
    if s.len == 4:
      result.r = parseHexInt(s[1..1]).uint8 * 0x11.uint8
      result.g = parseHexInt(s[2..2]).uint8 * 0x11.uint8
      result.b = parseHexInt(s[3..3]).uint8 * 0x11.uint8
      result.a = 255
    elif s.len == 5:
      result.r = parseHexInt(s[1..1]).uint8 * 0x11.uint8
      result.g = parseHexInt(s[2..2]).uint8 * 0x11.uint8
      result.b = parseHexInt(s[3..3]).uint8 * 0x11.uint8
      result.a = parseHexInt(s[4..4]).uint8 * 0x11.uint8
    elif s.len == 7:
      result.r = parseHexInt(s[1..2]).uint8
      result.g = parseHexInt(s[3..4]).uint8
      result.b = parseHexInt(s[5..6]).uint8
    elif s.len == 9:
      result.r = parseHexInt(s[1..2]).uint8
      result.g = parseHexInt(s[3..4]).uint8
      result.b = parseHexInt(s[5..6]).uint8
      result.a = parseHexInt(s[7..8]).uint8

const
  COLOR_BLACK* = newColor(0, 0, 0)
  COLOR_BLUE* = newColor(0, 0, 255)
  COLOR_GREEN* = newColor(0, 255, 0)
  COLOR_CYAN* = newColor(0, 255, 255)
  COLOR_RED* = newColor(255, 0, 0)
  COLOR_MAGENTA* = newColor(255, 0, 255)
  COLOR_YELLOW* = newColor(255, 255, 0)
  COLOR_WHITE* = newColor(255, 255, 255)
  COLOR_ORANGE* = newColor(255, 161, 0)
