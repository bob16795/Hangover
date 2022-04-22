import core/types/vector2
import core/types/point
import core/types/color
import core/types/rect
import core/types/font
import ui/elements/uielement
import ui/types/uisprite

type
  UIButton* = ref object of UIElement
    font: ptr Font
    action*: UIAction
    text*: string
    textUpdate*: UIUpdate
    hasTexture*: bool
    sprite*: Sprite
    hasSprite*: bool
    normalUI, clickedUI, disabledUI, focusedUI: UISprite
    toggle*: bool
    pressed*: bool

proc newUIButton*(texture: Texture, font: var Font, bounds: UIRectangle,
        action: UIAction = nil, text = "", disableProc: proc(): bool = nil,
            sprite: Sprite = Sprite(), toggle: bool = false): UIButton =
  result = UIButton()

  result.font = addr font

  result.isActive = true
  result.bounds = bounds
  result.isDisabled = disableProc
  if texture.isDefined():
    result.hasTexture = true
    result.normalUI = newUiSprite(texture, newRect(0, 0, 0.5, 1),
          newRect(0.125, 0.25, 0.125, 0.25)).scale(newVector2(64, 32))
    result.focusedUI = newUiSprite(texture, newRect(0.5, 0, 0.5, 1),
          newRect(0.625, 0.25, 0.125, 0.25)).scale(newVector2(64, 32))
    result.disabledUI = newUiSprite(texture, newRect(16, 0, 8, 8),
          newRect(18, 2, 4, 4))
  if action != nil:
    result.action = action
  else:
    result.action = proc(i: int) = discard
  result.text = text
  if sprite.texture.isDefined():
    result.sprite = sprite
    result.hasSprite = true
  result.toggle = toggle

method checkHover*(b: UIButton, parentRect: Rect, mousePos: Vector2): bool =
  b.focused = false
  if not b.isActive:
    return false
  if b.isDisabled != nil and b.isDisabled():
    return false

  if b.textUpdate != nil:
    b.text = b.textUpdate()
  var bounds = b.bounds.toRect(parentRect)
  if (bounds.x < mousePos.x and bounds.x +
          bounds.width > mousePos.x) and
      (bounds.y < mousePos.y and bounds.y +
              bounds.height > mousePos.y):
      b.focused = true
      return true

method click*(b: UIButton, button: int) =
  b.action(button)

method draw*(b: UIButton, parentRect: Rect) =
  if not b.isActive:
    return
  var bounds = b.bounds.toRect(parentRect)
  var sprite = b.normalUI
  var textColor = newColor(128, 128, 128, 255)
  if b.isDisabled != nil:
    if (b.isDisabled()):
      sprite = b.disabledUI
      textColor = newColor(128, 0, 0, 255)
    else:
      if b.focused:
        sprite = b.focusedUI
        textColor = newColor(0, 0, 0, 255)
  else:
    if b.focused:
      sprite = b.focusedUI
      textColor = newColor(0, 0, 0, 255)
  if (b.hasSprite):
    b.sprite.draw(newVector2(bounds.x + 2, bounds.y + 2),
        0, newVector2(bounds.height - 4, bounds.height - 4))
  if b.hasTexture:
    sprite.draw(bounds)
  if (b.text != ""):
    var posx: float32 = (bounds.x + ((
                bounds.width - sizeText(b.font[],
                b.text).x) / 2))
    var posy: float32 = (bounds.y + ((bounds.height - sizeText(b.font[],
        b.text).y) / 2))
    if b.hasSprite:
      posx = (bounds.x + bounds.width) - sizeText(b.font[],
          b.text).x
    b.font[].draw(b.text, newPoint(posx.cint, posy.cint), textColor)

method update*(b: var UIButton, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool =
  if not b.isActive:
    return false
  var bounds = b.bounds.toRect(parentRect)

  return false
