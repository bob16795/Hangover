import elements/uibutton
import elements/uielement
import elements/uirectangle
import core/events
import core/types/rect
import core/types/point
import core/types/vector2

export uibutton
export uielement
export uirectangle

type
  UIManager* {.acyclic.} = object
    elements: seq[UIElement]
    size: Vector2

var
  um*: UIManager

proc mouseMove*(data: pointer) =
  var pos = cast[ptr tuple[x, y: float64]](data)[]
  for e in um.elements:
    discard e.checkHover(newRect(newVector2(0, 0), um.size), newVector2(pos.x, pos.y))

proc resizeUI*(data: pointer) =
  var size = cast[ptr tuple[x, y: int32]](data)[]
  um.size = newVector2(size.x.float32, size.y.float32)

proc initUIManager*(size: Point) =
  um.size = newVector2(size.x.float32, size.y.float32)
  createListener(EVENT_MOUSE_MOVE, mouseMove)
  createListener(EVENT_RESIZE, resizeUI)

proc addUIElement*(e: UIElement) =
  um.elements.add(e)

proc addUIElements*(elems: seq[UIElement]) =
  um.elements.add(elems)

proc drawUI*() =
  for e in um.elements:
    e.draw(newRect(newVector2(0, 0), um.size))
