import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import hangover/core/logging
import sugar

#TODO: comment

type
  UIDynamic* = ref object of UIElement
    elements*: seq[UIElement]
    hasPopupAbove*: bool
    dragProc*: proc()
    dynamicUpdate*: () -> bool
    dynamicGenerate*: (e: UIDynamic) -> seq[UIElement]

proc newUIDynamic*(bounds: UIRectangle): UIDynamic =
  result = UIDynamic()
  result.isActive = true
  result.bounds = bounds

proc add*(g: var UIDynamic, e: UIElement) =
  g.elements.add(e)

proc clear*(g: var UIDynamic) =
  g.elements = @[]

method checkHover*(g: UIDynamic, parentRect: Rect, mousePos: Vector2) =
  g.focused = false
  if not g.isActive:
    return
  if g.isDisabled != nil and g.isDisabled():
    return

  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].checkHover(bounds, mousePos)
    if g.elements[i].focused:
      g.focused = true

method click*(g: UIDynamic, button: int) =
  for i in 0..<g.elements.len:
    if g.elements[i].focused:
      g.elements[i].click(button)
      capture i:
        g.dragProc = proc() = g.elements[i].drag(button)

method draw*(g: UIDynamic, parentRect: Rect) =
  if not g.isActive:
    return
  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].draw(bounds)

method update*(g: var UIDynamic, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not g.isActive:
    return
  if g.dynamicUpdate != nil and g.dynamicUpdate():
    g.elements = g.dynamicGenerate(g)
  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].update(bounds, mousePos, dt)

method drag*(g: UIDynamic, button: int) =
  if g.dragProc != nil:
    g.dragProc()

method scroll*(g: UIDynamic, offset: Vector2) =
  for i in 0..<g.elements.len:
    g.elements[i].scroll(offset)
