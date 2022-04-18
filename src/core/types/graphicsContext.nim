import glfw
import point

type
  GraphicsContext* = object
    window*: Window
  GraphicsInitData* = object
    name*: string
    size*: Point

proc newGraphicsInitData*(): GraphicsInitData =
  result.name = "Gin Game"
  result.size = newPoint(640, 480)
