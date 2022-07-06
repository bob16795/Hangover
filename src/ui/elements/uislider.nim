import core/types/vector2
import core/types/point
import core/types/color
import core/types/rect
import core/types/font
import ui/elements/uielement
import ui/types/uisprite
import sugar

#TODO: comment

type
  UISlider* = ref object of UIElement
    font*: ptr Font
    vertical*: bool
    sprite*, handleSprite*: UISprite
    value*: float
    handleSize*: float
    tmpVal: float
    update*: (v: float) -> void

method checkHover*(s: UISlider, parentRect: Rect, mousePos: Vector2) =
  s.focused = false

  var bounds = s.bounds.toRect(parentRect)

  if s.vertical:
    s.tmpVal = 1 - ((bounds.y - 15 + bounds.height -
        mousePos.y) / (bounds.height - 30))
  else:
    s.tmpVal = 1 - ((bounds.x - 15 + bounds.width -
        mousePos.x) / (bounds.width - 30))
  s.tmpVal = s.tmpVal.clamp(0, 1)

  if not s.isActive:
    return
  if s.isDisabled != nil and s.isDisabled():
    return

  if (bounds.x < mousePos.x and bounds.x +
          bounds.width > mousePos.x) and
      (bounds.y < mousePos.y and bounds.y +
              bounds.height > mousePos.y):
      s.focused = true

method click*(s: UISlider, button: int) =
  s.value = s.tmpVal
  if s.update != nil:
    s.update(s.value)

method drag*(s: UISlider, button: int) =
  s.value = s.tmpVal
  if s.update != nil:
    s.update(s.value)

method draw*(s: UISlider, parentRect: Rect) =
  if not s.isActive:
    return
  var bounds = s.bounds.toRect(parentRect)
  if true:
    var halfSize = s.handleSize / 2
    if s.vertical:
      var posy: float32 = ((bounds.y + halfSize) * (1 -
          s.value)) + (bounds.y + bounds.height -
          halfSize) * (s.value) - halfSize
      var posx: float32 = ((bounds.x + bounds.width) + bounds.x) / 2
      s.sprite.draw(newRect(posx - 2, bounds.y, 4, bounds.height))
      s.sprite.draw(newRect(bounds.x, posy, bounds.width, s.handleSize))
    else:
      var posx: float32 = ((bounds.x + halfSize) * (1 -
          s.value)) + (bounds.x + bounds.width -
          halfSize) * (s.value) - halfSize
      var posy: float32 = ((bounds.y + bounds.height) + bounds.y) / 2
      s.sprite.draw(newRect(bounds.x, posy - 16, bounds.width, 32))
      s.handleSprite.draw(newRect(posx, bounds.y, s.handleSize, bounds.height))

method update*(s: var UISlider, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not s.isActive:
    return

  var bounds = s.bounds.toRect(parentRect)
