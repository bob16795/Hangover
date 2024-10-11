import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import options

#TODO: comment

type
  UIPanel* = ref object of UIElement
    texture*: UISprite
    popup*: bool
    color*: UIField[Color]

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
  let bounds = p.bounds.toRect(parentRect)
  p.texture.draw(bounds, color = p.color.value, contrast = ContrastEntry(mode: bg))
