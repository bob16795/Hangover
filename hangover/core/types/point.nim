import math

# TODO: deprecate

type
  Point* = object
    x*: int
    y*: int

# const

func newPoint*(x, y: int | cint): Point =
  result.x = x
  result.y = y

# operators

func `*`*(p: Point, i: int): Point =
  result = p
  result.x *= i
  result.y *= i

func `*`*(i: int, p: Point): Point =
  result = p
  result.x *= i
  result.y *= i

func `+`*(p: Point, a: Point): Point =
  result = p
  result.x += a.x
  result.y += a.y

func `-`*(p: Point, a: Point): Point =
  result = p
  result.x -= a.x
  result.y -= a.y

func `/`*(p: Point, i: int): Point =
  result = p
  result.x = (result.x / i).int
  result.y = (result.y / i).int

# equals operators

func `*=`*(p: var Point, i: int) =
  p.x *= i
  p.y *= i

func `/=`*(p: var Point, i: int) =
  p.x = (p.x / i).int
  p.y = (p.y / i).int

func `+=`*(p: var Point, a: Point) =
  p.x += a.x
  p.y += a.y

func `-=`*(p: var Point, a: Point) =
  p.x -= a.x
  p.y -= a.y

# utils

func distance*(a, b: Point): float =
  let
    cx = (a.x - b.x).float32
    cy = (a.y - b.y).float32
  return sqrt(cx * cx + cy * cy)

func `angle=`*(p: var Point, radians: float32) =
  p.x = cos(radians).int
  p.y = sin(radians).int

func angle*(p: Point): float32 =
  return arctan2(p.x.float32, p.y.float32)

func rotated*(p: Point, phi: float32): Point =
  result.angle = phi + p.angle
  result = result * p.distance(newPoint(0, 0)).int

func rotate*(p: var Point, phi: float32) =
  p = p.rotated(phi)
