import vector2

type
  Rect* = object of RootObj
    x*: float32
    y*: float32
    width*: float32
    height*: float32

proc newRect*(x, y: float32, width, height: float32): Rect =
  result.x = x
  result.y = y
  result.width = width
  result.height = height

proc newRect*(position, size: Vector2): Rect =
  result.x = position.x
  result.y = position.y
  result.width = size.x
  result.height = size.y

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
