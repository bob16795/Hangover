import core/types/vector2
import core/types/point
import core/types/color
import core/types/rect
import core/types/font
import ui/elements/uielement
import ui/types/uisprite

type
  UIPanel* = ref object of UIElement
    texture*: UISprite
    popup*: bool
    color*: Color

proc newUIPanel*(sprite: UISprite, bounds: UIRectangle,
    popup: bool): UIPanel =
  result = UIPanel()
  result.texture = sprite
  result.isActive = true
  result.bounds = bounds
  result.popup = popup


method checkHover*(p: UIPanel, parentRect: Rect, mousePos: Vector2): bool =
  return false

method draw*(p: UIPanel, parentRect: Rect) =
  if not p.isActive:
    return
  var bounds = p.bounds.toRect(parentRect)
  # if p.popup:
  #   drawFill(initRectangle(initPoint(0, 0), getWindowSize()), initColor(0,
  #       0, 0, 128))
  if p.texture.texture.isDefined():
    p.texture.draw(bounds, c = p.color, layer = 499)

method update*(p: var UIPanel, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool =
  if not p.isActive:
    return false
  var bounds = p.bounds.toRect(parentRect)

  return false
