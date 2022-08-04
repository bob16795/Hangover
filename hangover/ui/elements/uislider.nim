import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/logging
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import sugar

#TODO: comment

type
  UISlider* = ref object of UIElement
    font*: ptr Font
    vertical*: bool
    sprite*, handleSprite*: UISprite
    value*: float
    handleSize*: float
    barSize*: float
    tmpVal: float
    update*: (v: float) -> void
    scrollSensitivity*: float

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
      var posx: float32 = bounds.x + (bounds.width) / 2
      s.sprite.draw(newRect(posx - s.barSize / 2, bounds.y, s.barSize, bounds.height))
      s.handleSprite.draw(newRect(bounds.x, posy, bounds.width, s.handleSize))
    else:
      var posx: float32 = ((bounds.x + halfSize) * (1 -
          s.value)) + (bounds.x + bounds.width -
          halfSize) * (s.value) - halfSize
      var posy: float32 = bounds.y + (bounds.height) / 2
      s.sprite.draw(newRect(bounds.x, posy - s.barSize / 2, bounds.width, s.barSize))
      s.handleSprite.draw(newRect(posx, bounds.y, s.handleSize, bounds.height))

method update*(s: var UISlider, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not s.isActive:
    return

  var bounds = s.bounds.toRect(parentRect)

method drag*(e: UISlider, button: int) =
  e.value = e.tmpVal
  if e.update != nil:
    e.update(e.value)

method scroll*(e: UISlider, offset: Vector2) =
  if e.vertical:
    e.value += e.scrollSensitivity * offset.y
  else:
    e.value += e.scrollSensitivity * offset.x
  e.value = clamp(e.value, 0, 1)
  if e.update != nil:
    e.update(e.value)
