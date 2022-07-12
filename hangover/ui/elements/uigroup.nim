import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import hangover/core/logging

#TODO: comment

type
  UIGroup* = ref object of UIElement
    elements*: seq[UIElement]
    hasPopupAbove*: bool

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
  LOG_TRACE("uigroup", bounds)
  for i in 0..<g.elements.len:
    g.elements[i].update(bounds, mousePos, dt)
