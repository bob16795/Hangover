import core/types/vector2
import core/types/point
import core/types/color
import core/types/shader
import core/types/rect
import core/types/font
import ui/elements/uielement
import ui/types/uisprite

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

  var bounds = b.bounds.toRect(parentRect)

method click*(b: UIImage, button: int) =
  discard

method draw*(b: UIImage, parentRect: Rect) =
  if not b.isActive:
    return
  
  var bounds = b.bounds.toRect(parentRect)
  if b.size.x != 0 and b.size.y != 0:
    var scale = min(bounds.width / b.size.x, bounds.height / b.size.y)
    var center = bounds.center
    bounds.size = b.size * scale
    bounds.location = center - bounds.size / 2

  b.sprite.draw(bounds.location, 0, bounds.size, c = b.color)

method update*(b: var UIImage, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not b.isActive:
    return
  var bounds = b.bounds.toRect(parentRect)
