import vector2

# TODO: comment

type
  Rect* = object of RootObj
    x*: float32
    y*: float32
    width*: float32
    height*: float32

proc newRect*(x, y, width, height: int | float | float32 | float64): Rect =
  result.x = x.float32
  result.y = y.float32
  result.width = width.float32
  result.height = height.float32

proc newRect*(x, y: int | float | float32 | float64, size: Vector2): Rect =
  result.x = x.float32
  result.y = y.float32
  result.width = size.x
  result.height = size.y

proc newRect*(position: Vector2, width, height: int | float | float32 | float64): Rect =
  result.x = position.x
  result.y = position.y
  result.width = width.float32
  result.height = height.float32

proc newRect*(position, size: Vector2): Rect =
  result.x = position.x
  result.y = position.y
  result.width = size.x
  result.height = size.y

proc fix*(r: Rect): Rect =
  result = r
  if result.width < 0:
    result.width *= -1
    result.x -= result.width
  if result.height < 0:
    result.height *= -1
    result.y -= result.height

proc size*(r: Rect): Vector2 =
  result.x = r.width
  result.y = r.height

proc `size=`*(r: var Rect, size: Vector2) =
  r.width = size.x
  r.height = size.y

proc location*(r: Rect): Vector2 =
  result.x = r.x
  result.y = r.y

proc `location=`*(r: var Rect, p: Vector2) =
  r.x = p.x
  r.y = p.y

proc offset*(r: Rect, offset: Vector2): Rect =
  result.x = r.x + offset.x
  result.y = r.y + offset.y
  result.width = r.width
  result.height = r.height

proc center*(r: Rect): Vector2 =
  return newVector2(r.x + (r.width / 2).float32, r.y + (r.height / 2).float32)

proc clamp*(v: Vector2, r: Rect): Vector2 =
  result.x = v.x.clamp(r.x, r.x + r.width)
  result.y = v.y.clamp(r.y, r.y + r.height)

proc contains*(r: Rect, v: Vector2): bool =
  return r.x < v.x and
         r.y < v.y and
         r.x + r.width > v.x and
         r.y + r.height > v.y

proc contains*(r: Rect, v: Rect): bool =
  var halfSize = v.size / 2
  var r2 = r
  return r2.contains(v.center)
