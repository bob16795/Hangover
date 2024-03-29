import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/shader
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite

#TODO: comment

type
  UIImage* = ref object of UIElement
    sprite*: Sprite
    color*: Color
    size*: Vector2

method checkHover*(b: UIImage, parentRect: Rect, mousePos: Vector2) =
  b.focused = false
  if not b.isActive:
    return
  if b.isDisabled != nil and b.isDisabled():
    return

  let bounds = b.bounds.toRect(parentRect)

method click*(b: UIImage, button: int) =
  discard

method draw*(b: UIImage, parentRect: Rect) =
  if not b.isActive:
    return
  
  var bounds = b.bounds.toRect(parentRect)
  if b.size.x != 0 and b.size.y != 0:
    let scale = min(bounds.width / b.size.x, bounds.height / b.size.y)
    let center = bounds.center
    bounds.size = b.size * scale
    bounds.location = center - bounds.size / 2

  b.sprite.draw(bounds.location, 0, bounds.size, c = b.color)

method update*(b: UIImage, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not b.isActive:
    return
  var bounds = b.bounds.toRect(parentRect)
