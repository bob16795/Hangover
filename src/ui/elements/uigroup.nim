import core/types/vector2
import core/types/point
import core/types/color
import core/types/rect
import core/types/font
import ui/elements/uielement
import ui/types/uisprite

type
  UIGroup* = ref object of UIElement
    groupElements: seq[UIElement]
    hasPopupAbove*: bool

proc newUIGroup*(bounds: UIRectangle): UIGroup =
  result = UIGroup()
  result.isActive = true
  result.bounds = bounds

proc add*(g: var UIGroup, e: UIElement) =
  g.groupElements.add(e)

proc clear*(g: var UIGroup) =
  g.groupElements = @[]

method checkHover*(g: UIGroup, parentRect: Rect, mousePos: Vector2): bool =
  g.focused = false
  if not g.isActive:
    return false
  if g.isDisabled != nil and g.isDisabled():
    return false

  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.groupElements.len:
    if g.groupElements[i].checkHover(bounds, mousePos):
      g.focused = true

method click*(g: UIGroup, button: int) =
  for i in 0..<g.groupElements.len:
    if g.groupElements[i].focused:
      g.groupElements[i].click(button)



method draw*(g: UIGroup, parentRect: Rect) =
  if not g.isActive:
    return
  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.groupElements.len:
    g.groupElements[i].draw(bounds)

method update*(g: var UIGroup, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool =
  if not g.isActive:
    return
  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.groupElements.len:
    discard g.groupElements[i].update(bounds, mousePos, dt)
  return false
