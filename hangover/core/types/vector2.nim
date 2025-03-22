import math
import point

# TODO: comment

type
  Vector2* = object
    x*: float32
    y*: float32

{.push inline.}

# const
func newVector2*(x: int | int16 | int32 | float | float32 | float64): Vector2 =
  result.x = x.float32
  result.y = x.float32

func newVector2*(x, y: int | int16 | int32 | float | float32 | float64): Vector2 =
  result.x = x.float32
  result.y = y.float32

# operators

func `*`*(p: Vector2, i: int | int16 | int32 | float | float32 | float64): Vector2 =
  result = p
  result.x *= i.float32
  result.y *= i.float32

func `*`*(i: int | int16 | int32 | float | float32 | float64, p: Vector2): Vector2 =
  result = p
  result.x *= i.float32
  result.y *= i.float32

func `+`*(p: Vector2, a: Vector2): Vector2 =
  result = p
  result.x += a.x
  result.y += a.y

func `-`*(p: Vector2, a: Vector2): Vector2 =
  result = p
  result.x -= a.x
  result.y -= a.y

func `/`*(p: Vector2, i: int | int16 | int32 | float | float32 | float64): Vector2 =
  result = p
  result.x /= i.float32
  result.y /= i.float32

func `/`*(i: int | int16 | int32 | float | float32 | float64, p: Vector2): Vector2 =
  result = p
  result.x = i.float32 / result.x
  result.y = i.float32 / result.y

func `-`*(p: Vector2): Vector2 =
  result = p * -1

# equals operators

func `*=`*(p: var Vector2, i: int | int16 | int32 | float | float32 | float64) =
  p.x *= i.float32
  p.y *= i.float32

func `/=`*(p: var Vector2, i: int | int16 | int32 | float | float32 | float64) =
  p.x = (p.x / i.float32)
  p.y = (p.y / i.float32)

func `+=`*(p: var Vector2, a: Vector2) =
  p.x += a.x
  p.y += a.y

func `-=`*(p: var Vector2, a: Vector2) =
  p.x -= a.x
  p.y -= a.y

# utils
func distance*(a, b: Vector2): float =
  let
    cx = (a.x - b.x).float32
    cy = (a.y - b.y).float32
  return sqrt(cx * cx + cy * cy)

func distanceSq*(a, b: Vector2): float =
  let
    cx = (a.x - b.x).float32
    cy = (a.y - b.y).float32
  return cx * cx + cy * cy

func mag*(a: Vector2): float =
  return sqrt(a.x * a.x + a.y * a.y)

func magSq*(a: Vector2): float =
  return a.x * a.x + a.y * a.y

func `angle=`*(p: var Vector2, radians: int | int16 | int32 | float | float32 | float64) =
  let mag = p.mag.float32
  p.x = cos(radians).float32
  p.y = sin(radians).float32
  p *= mag

func angle*(p: Vector2): int | int16 | int32 | float | float32 | float64 =
  return arctan2(p.y.float32, p.x.float32)

func rotated*(p: Vector2, phi: int | int16 | int32 | float | float32 | float64): Vector2 =
  result = p
  result.angle = phi.float32 + p.angle

func rotate*(p: var Vector2, phi: int | int16 | int32 | float | float32 | float64) =
  p = p.rotated(phi)

func round*(p: Vector2): Vector2 =
  result.x = p.x.round
  result.y = p.y.round

func toPoint*(p: Vector2): Point =
  result.x = p.x.cint
  result.y = p.y.cint

func toVector2*(p: Point): Vector2 =
  result.x = p.x.float32
  result.y = p.y.float32

func normal*(p: Vector2): Vector2 =
  let mag = p.mag
  if mag == 0: return newVector2(0, 0)
  result.x = p.x / mag
  result.y = p.y / mag
  if result.x.isNaN: result.x = 0
  if result.y.isNaN: result.y = 0

func dot*(a, b: Vector2): float32 =
  a.x * b.x + a.y * b.y

func `$`*(v: Vector2): string =
  "(" & $v.x & ", " & $v.y & ")"

func lerp*(a, b: Vector2, pc: float): Vector2 =
  a + (b - a) * pc

func clampMag*(v: Vector2, min: float32, max: float32): Vector2 =
  if v.mag == 0: return Vector2()
  v.normal * clamp(v.mag, min, max)

{.pop.}
