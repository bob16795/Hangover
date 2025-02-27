import vector2

type
  Rect* = object
    ## a rectangle object
    x*: float32
    y*: float32
    width*: float32
    height*: float32

func newRect*(x, y, width, height: int | int16 | int32 | float | float32 | float64): Rect =
  ## creates a rectangle
  result.x = x.float32
  result.y = y.float32
  result.width = width.float32
  result.height = height.float32

func newRect*(x, y: int | float | float32 | float64, size: Vector2): Rect =
  ## creates a rectangle
  result.x = x.float32
  result.y = y.float32
  result.width = size.x
  result.height = size.y

func newRect*(position: Vector2, width, height: int | float | float32 | float64): Rect =
  ## creates a rectangle
  result.x = position.x
  result.y = position.y
  result.width = width.float32
  result.height = height.float32

func newRect*(position, size: Vector2): Rect =
  ## creates a rectangle
  result.x = position.x
  result.y = position.y
  result.width = size.x
  result.height = size.y

func fix*(r: Rect): Rect =
  ## fixes a rects bounds if negative
  result = r
  if result.width < 0:
    result.width *= -1
    result.x -= result.width
  if result.height < 0:
    result.height *= -1
    result.y -= result.height

func size*(r: Rect): Vector2 =
  ## gets the size of a rectangle
  result.x = r.width
  result.y = r.height

func `size=`*(r: var Rect, size: Vector2) =
  ## sets the size of a rectangle
  r.width = size.x
  r.height = size.y

func location*(r: Rect): Vector2 =
  ## gets the location of a rectangle
  result.x = r.x
  result.y = r.y

func `location=`*(r: var Rect, p: Vector2) =
  ## sets the location of a rectangle
  r.x = p.x
  r.y = p.y

func offset*(r: Rect, offset: Vector2): Rect =
  ## moves a rectangle
  result.x = r.x + offset.x
  result.y = r.y + offset.y
  result.width = r.width
  result.height = r.height

func center*(r: Rect): Vector2 =
  ## geets the center of a rectangle
  return r.location + r.size / 2

func clamp*(v: Vector2, r: Rect): Vector2 =
  ## clamps a vector2 into a rectangle
  result.x = v.x.clamp(r.x, r.x + r.width)
  result.y = v.y.clamp(r.y, r.y + r.height)

func contains*(r: Rect, v: Vector2): bool =
  ## checks if a vector2 is in a rectangle
  return r.x < v.x and
         r.y < v.y and
         r.x + r.width > v.x and
         r.y + r.height > v.y

func contains*(r: Rect, v: Rect): bool =
  ## checks aabb for a rectangle
  return (r.x < v.x + v.width and r.x + r.width > v.x) and
         (r.y < v.y + v.height and r.y + r.height > v.y)

func scale*(r: Rect, scale: float32): Rect =
  result = r

  result.x *= scale
  result.y *= scale
  result.width *= scale
  result.height *= scale

func expand*(r: Rect, border: float32): Rect =
  newRect(
    r.x - border,
    r.y - border,
    r.width + border * 2,
    r.height + border * 2,
  )
