import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite

#TODO: comment

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


method checkHover*(p: UIPanel, parentRect: Rect, mousePos: Vector2) =
  return

method draw*(p: UIPanel, parentRect: Rect) =
  if not p.isActive:
    return
  var bounds = p.bounds.toRect(parentRect)
  p.texture.draw(bounds, c = p.color)

method update*(p: UIPanel, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not p.isActive:
    return
  var bounds = p.bounds.toRect(parentRect)
