import point

type
  Rect* = object of RootObj
    x*: cint
    y*: cint
    width*: cint
    height*: cint

proc newRect*(x, y: cint, width, height: cint): Rect =
  result.x = x
  result.y = y
  result.width = width
  result.height = height

proc newRect*(position, size: Point): Rect =
  result.x = position.x
  result.y = position.y
  result.width = size.x
  result.height = size.y

proc size*(r: Rect): Point =
  result.x = r.width
  result.y = r.height

proc `size=`*(r: var Rect, size: Point) =
  r.width = size.x
  r.height = size.y

proc location*(r: Rect): Point =
  result.x = r.x
  result.y = r.y

proc `location=`*(r: var Rect, p: Point) =
  r.x = p.x
  r.y = p.y

proc offset*(r: Rect, offset: Point): Rect =
  result.x = r.x + offset.x
  result.y = r.y + offset.y
  result.width = r.width
  result.height = r.height

proc center*(r: Rect): Point =
  return newPoint(r.x + (r.width / 2).cint, r.y + (r.height / 2).cint)
