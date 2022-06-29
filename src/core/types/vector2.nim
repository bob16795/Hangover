import math
import point

type
  Vector2* = object
    x*: float32
    y*: float32

# const

proc newVector2*(x, y: int | int16 | int32 | float | float32 | float64): Vector2 =
  result.x = x.float32
  result.y = y.float32

# operators

proc `*`*(p: Vector2, i: int | int16 | int32 | float | float32 | float64): Vector2 =
  result = p
  result.x *= i.float32
  result.y *= i.float32

proc `*`*(i: int | int16 | int32 | float | float32 | float64, p: Vector2): Vector2 =
  result = p
  result.x *= i.float32
  result.y *= i.float32

proc `+`*(p: Vector2, a: Vector2): Vector2 =
  result = p
  result.x += a.x
  result.y += a.y

proc `-`*(p: Vector2, a: Vector2): Vector2 =
  result = p
  result.x -= a.x
  result.y -= a.y

proc `/`*(p: Vector2, i: int | int16 | int32 | float | float32 | float64): Vector2 =
  result = p
  result.x /= i.float32
  result.y /= i.float32

proc `-`*(p: Vector2): Vector2 =
  result = result * -1

# equals operators

proc `*=`*(p: var Vector2, i: int | int16 | int32 | float | float32 | float64) =
  p.x *= i.float32
  p.y *= i.float32

proc `/=`*(p: var Vector2, i: int | int16 | int32 | float | float32 | float64) =
  p.x = (p.x / i.float32)
  p.y = (p.y / i.float32)

proc `+=`*(p: var Vector2, a: Vector2) =
  p.x += a.x
  p.y += a.y

proc `-=`*(p: var Vector2, a: Vector2) =
  p.x -= a.x
  p.y -= a.y

# utils

proc distance*(a, b: Vector2): float =
  let
    cx = (a.x - b.x).float32
    cy = (a.y - b.y).float32
  return sqrt(cx * cx + cy * cy)

proc distanceSq*(a, b: Vector2): float =
  let
    cx = (a.x - b.x).float32
    cy = (a.y - b.y).float32
  return cx * cx + cy * cy

proc `angle=`*(p: var Vector2, radians: int | int16 | int32 | float | float32 | float64) =
  let mag = p.distance(newVector2(0, 0)).float32
  p.x = cos(radians).float32
  p.y = sin(radians).float32
  p *= mag

proc angle*(p: Vector2): int | int16 | int32 | float | float32 | float64 =
  return arctan2(p.y.float32, p.x.float32)

proc rotated*(p: Vector2, phi: int | int16 | int32 | float | float32 | float64): Vector2 =
  result.angle = phi.float32 + p.angle

proc rotate*(p: var Vector2, phi: int | int16 | int32 | float | float32 | float64) =
  p = p.rotated(phi)

proc toPoint*(p: Vector2): Point =
  result.x = p.x.cint
  result.y = p.y.cint

proc toVector2*(p: Point): Vector2 =
  result.x = p.x.float32
  result.y = p.y.float32
