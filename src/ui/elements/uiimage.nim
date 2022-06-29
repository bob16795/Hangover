import core/types/vector2
import core/types/point
import core/types/color
import core/types/shader
import core/types/rect
import core/types/font
import ui/elements/uielement
import ui/types/uisprite

type
  UIImage* = ref object of UIElement
    sprite*: Sprite
    color*: Color

method checkHover*(b: UIImage, parentRect: Rect, mousePos: Vector2): bool =
  b.focused = false
  if not b.isActive:
    return false
  if b.isDisabled != nil and b.isDisabled():
    return false

  var bounds = b.bounds.toRect(parentRect)
  return false

method click*(b: UIImage, button: int) =
  discard

method draw*(b: UIImage, parentRect: Rect) =
  if not b.isActive:
    return

  var bounds = b.bounds.toRect(parentRect)

  b.sprite.draw(bounds.location, 0, bounds.size, c = b.color)

method update*(b: var UIImage, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool =
  if not b.isActive:
    return false
  var bounds = b.bounds.toRect(parentRect)

  return false
