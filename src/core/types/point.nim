import math

type
  Point* = object
    x*: cint
    y*: cint

# const

proc newPoint*(x, y: cint): Point =
  result.x = x
  result.y = y

proc newPoint*(x, y: int): Point =
  result.x = x.cint
  result.y = y.cint

# operators

proc `*`*(p: Point, i: cint): Point =
  result = p
  result.x *= i
  result.y *= i

proc `*`*(i: cint, p: Point): Point =
  result = p
  result.x *= i
  result.y *= i

proc `+`*(p: Point, a: Point): Point =
  result = p
  result.x += a.x
  result.y += a.y

proc `-`*(p: Point, a: Point): Point =
  result = p
  result.x -= a.x
  result.y -= a.y
  
proc `/`*(p: Point, i: cint): Point =
  result = p
  result.x = (result.x / i).cint
  result.y = (result.y / i).cint

# equals operators

proc `*=`*(p: var Point, i: cint) =
  p.x *= i
  p.y *= i
  
proc `/=`*(p: var Point, i: cint) =
  p.x = (p.x / i).cint
  p.y = (p.y / i).cint

proc `+=`*(p: var Point, a: Point) =
  p.x += a.x
  p.y += a.y

proc `-=`*(p: var Point, a: Point) =
  p.x -= a.x
  p.y -= a.y

# utils

proc distance*(a, b: Point): float =
  var cx, cy: float32
  cx = (a.x - b.x).float32
  cy = (a.y - b.y).float32
  return sqrt(cx * cx + cy * cy)

proc `angle=`*(p: var Point, radians: float32) =
  p.x = cos(radians).cint
  p.y = sin(radians).cint

proc angle*(p: Point): float32 =
  return arctan2(p.x.float32, p.y.float32)

proc rotated*(p: Point, phi: float32): Point =
  result.angle = phi + p.angle
  result = result * p.distance(newPoint(0, 0)).cint

proc rotate*(p: var Point, phi: float32) =
  p = p.rotated(phi)
