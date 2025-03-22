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
  newRect(
    if r.width < 0: r.x + r.width else: r.x,
    if r.height < 0: r.y + r.height else: r.y,
    abs(r.width),
    abs(r.height),
  )

func size*(r: Rect): Vector2 =
  ## gets the size of a rectangle
  newVector2(
    r.width,
    r.height,
  )

func `size=`*(r: var Rect, size: Vector2) =
  ## sets the size of a rectangle
  r.width = size.x
  r.height = size.y

func location*(r: Rect): Vector2 =
  ## gets the location of a rectangle
  newVector2(
    r.x,
    r.y,
  )

func `location=`*(r: var Rect, p: Vector2) =
  ## sets the location of a rectangle
  r.x = p.x
  r.y = p.y

func offset*(r: Rect, offset: Vector2): Rect =
  ## moves a rectangle
  newRect(
    r.x + offset.x,
    r.y + offset.y,
    r.width,
    r.height,
  )

func sizeOffset*(r: Rect, offset: Vector2): Rect =
  ## moves a rectangle
  newRect(
    r.x,
    r.y,
    r.width + offset.x,
    r.height + offset.y,
  )

func center*(r: Rect): Vector2 =
  ## geets the center of a rectangle
  r.location + r.size / 2

func clamp*(v: Vector2, r: Rect): Vector2 =
  ## clamps a vector2 into a rectangle
  newVector2(
    v.x.clamp(r.x, r.x + r.width),
    v.y.clamp(r.y, r.y + r.height),
  )

func contains*(r: Rect, v: Vector2): bool =
  ## checks if a vector2 is in a rectangle
  r.x < v.x and
  r.y < v.y and
  r.x + r.width > v.x and
  r.y + r.height > v.y

func contains*(r: Rect, v: Rect): bool =
  ## checks aabb for a rectangle
  return (r.x < v.x + v.width and r.x + r.width > v.x) and
         (r.y < v.y + v.height and r.y + r.height > v.y)

func scale*(r: Rect, scale: Vector2): Rect =
  newRect(
    r.x * scale.x,
    r.y * scale.y,
    r.width * scale.x,
    r.height * scale.y,
  )

func scale*(r: Rect, scale: float32): Rect =
  r.scale(newVector2(scale))

func expand*(r: Rect, border: float32): Rect =
  newRect(
    r.x - border,
    r.y - border,
    r.width + border * 2,
    r.height + border * 2,
  )
