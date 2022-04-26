import ui/elements/uielement
import ui/elements/uibutton
import ui/elements/uipanel
import ui/elements/uigroup
import ui/elements/uitext
import ui/types/uirectangle
import core/events
import core/types/rect
import core/types/point
import core/types/vector2

export uitext
export uipanel
export uigroup
export uibutton
export uielement
export uirectangle

type
  UIManager* {.acyclic.} = object
    elements: seq[UIElement]
    size: Vector2
    mousePos: Vector2

var
  um*: UIManager

proc mouseMove*(data: pointer) =
  var pos = cast[ptr tuple[x, y: float64]](data)[]
  um.mousePos = newVector2(pos.x, pos.y)
  for e in um.elements:
    discard e.checkHover(newRect(newVector2(0, 0), um.size), um.mousePos)

proc mouseClick*(data: pointer) =
  var btn = cast[ptr int](data)[]
  for e in um.elements:
    if e.focused:
      e.click(btn)

proc resizeUI*(data: pointer) =
  var size = cast[ptr tuple[x, y: int32]](data)[]
  um.size = newVector2(size.x.float32, size.y.float32)

proc initUIManager*(size: Point) =
  um.size = newVector2(size.x.float32, size.y.float32)
  createListener(EVENT_MOUSE_MOVE, mouseMove)
  createListener(EVENT_MOUSE_CLICK, mouseClick)
  createListener(EVENT_RESIZE, resizeUI)

proc addUIElement*(e: UIElement) =
  um.elements.add(e)

proc addUIElements*(elems: seq[UIElement]) =
  um.elements.add(elems)

proc drawUI*() =
  for e in um.elements:
    e.draw(newRect(newVector2(0, 0), um.size))

proc updateUI*(dt: float32) =
  for i in 0..<len um.elements:
    discard um.elements[i].update(newRect(newVector2(0, 0), um.size),
        um.mousePos, dt)

proc setUIActive*(i: int, value: bool) =
  um.elements[i].isActive = value
