import math
import point

type
  Vector2* = object
    x*: float32
    y*: float32

# const

proc newVector2*(x, y: float32): Vector2 =
  result.x = x
  result.y = y

proc newVector2*(x, y: int): Vector2 =
  result.x = x.float32
  result.y = y.float32

# operators

proc `*`*(p: Vector2, i: float32): Vector2 =
  result = p
  result.x *= i
  result.y *= i

proc `*`*(i: float32, p: Vector2): Vector2 =
  result = p
  result.x *= i
  result.y *= i

proc `+`*(p: Vector2, a: Vector2): Vector2 =
  result = p
  result.x += a.x
  result.y += a.y

proc `-`*(p: Vector2, a: Vector2): Vector2 =
  result = p
  result.x -= a.x
  result.y -= a.y

proc `/`*(p: Vector2, i: float32): Vector2 =
  result = p
  result.x = (result.x / i).float32
  result.y = (result.y / i).float32

# equals operators

proc `*=`*(p: var Vector2, i: float32) =
  p.x *= i
  p.y *= i

proc `/=`*(p: var Vector2, i: float32) =
  p.x = (p.x / i).float32
  p.y = (p.y / i).float32

proc `+=`*(p: var Vector2, a: Vector2) =
  p.x += a.x
  p.y += a.y

proc `-=`*(p: var Vector2, a: Vector2) =
  p.x -= a.x
  p.y -= a.y

# utils

proc distance*(a, b: Vector2): float =
  var cx, cy: float32
  cx = (a.x - b.x).float32
  cy = (a.y - b.y).float32
  return sqrt(cx * cx + cy * cy)

proc `angle=`*(p: var Vector2, radians: float32) =
  p.x = cos(radians).float32
  p.y = sin(radians).float32

proc angle*(p: Vector2): float32 =
  return arctan2(p.x.float32, p.y.float32)

proc rotated*(p: Vector2, phi: float32): Vector2 =
  result.angle = phi + p.angle
  result = result * p.distance(newVector2(0, 0)).float32

proc rotate*(p: var Vector2, phi: float32) =
  p = p.rotated(phi)

proc toPoint*(p: Vector2): Point =
  result.x = p.x.cint
  result.y = p.y.cint

proc toVector2*(p: Point): Vector2 =
  result.x = p.x.float32
  result.y = p.y.float32
