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
  UIGroup* = ref object of UIElement
    elements*: seq[UIElement]
    hasPopupAbove*: bool
    dragProc*: proc()

proc newUIGroup*(bounds: UIRectangle): UIGroup =
  result = UIGroup()
  result.isActive = true
  result.bounds = bounds

proc add*(g: var UIGroup, e: UIElement) =
  g.elements.add(e)

proc clear*(g: var UIGroup) =
  g.elements = @[]

method checkHover*(g: UIGroup, parentRect: Rect, mousePos: Vector2) =
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

method click*(g: UIGroup, button: int) =
  for i in 0..<g.elements.len:
    if g.elements[i].focused:
      g.elements[i].click(button)
      capture i:
        g.dragProc = proc() = g.elements[i].drag(button)

method draw*(g: UIGroup, parentRect: Rect) =
  if not g.isActive:
    return
  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].draw(bounds)

method update*(g: var UIGroup, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not g.isActive:
    return
  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].update(bounds, mousePos, dt)

method drag*(g: UIGroup, button: int) =
  if g.dragProc != nil:
    g.dragProc()

method scroll*(g: UIGroup, offset: Vector2) =
  for i in 0..<g.elements.len:
    g.elements[i].scroll(offset)

method `active=`*(g: UIGroup, value: bool) =
  g.isActive = value
  if not value:
    g.focused = false
  for e in g.elements:
    e.active = value
