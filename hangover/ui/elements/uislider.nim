import hangover/core/types/vector2
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/types/color
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import options
import sugar

#TODO: comment

type
  UISlider* = ref object of UIElement
    font*: Font
    fontMult*: float32
    valueMul*: float
    valueAdd*: float
    valueLabel*: string

    vertical*: bool
    sprite*, handleSprite*: UISprite
    focusedSprite*: UISprite
    value*: float
    valueVis*: float
    handleSize*: float
    barSize*: float
    default*: float
    tmpVal: float
    update*: (v: float) -> void
    release*: (v: float) -> void
    scrollSensitivity*: float
    smooth*: float32

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
  if s.disabled.value:
    return

  if (bounds.x < mousePos.x and bounds.x +
          bounds.width > mousePos.x) and
      (bounds.y < mousePos.y and bounds.y +
              bounds.height > mousePos.y):
      s.focused = true

method click*(s: UISlider, button: int) =
  if not s.focused:
    return

  s.value = s.tmpVal
  if s.update != nil:
    s.update(s.value)

method draw*(s: UISlider, parentRect: Rect) =
  if not s.isActive:
    return
  var bounds = s.bounds.toRect(parentRect)
  if true:
    var handleSprite = s.handleSprite
    if s.focused:
      handleSprite = s.focusedSprite

    var halfSize = s.handleSize / 2
    if s.vertical:
      var posy: float32 = ((bounds.y + halfSize) * (1 -
          s.valueVis)) + (bounds.y + bounds.height -
          halfSize) * (s.valueVis) - halfSize
      var posx: float32 = bounds.x + (bounds.width) / 2
      s.sprite.draw(newRect(posx - s.barSize / 2, bounds.y, s.barSize, bounds.height), fg = some(true))
      handleSprite.draw(newRect(bounds.x, posy, bounds.width, s.handleSize), fg = some(true))
    else:
      var posx: float32 = ((bounds.x + halfSize) * (1 -
          s.valueVis)) + (bounds.x + bounds.width -
          halfSize) * (s.valueVis) - halfSize
      var posy: float32 = bounds.y + (bounds.height) / 2
      s.sprite.draw(newRect(bounds.x, posy - s.barSize / 2, bounds.width, s.barSize), fg = some(true))
      handleSprite.draw(newRect(posx, bounds.y, s.handleSize, bounds.height), fg = some(true))
      if s.font != nil:
        let
          handlePos = newRect(posx, bounds.y, s.handleSize, bounds.height).center()
          text = $int(s.value * s.valueMul + s.valueAdd) & s.valueLabel
          size = s.font.sizeText(text, s.fontMult * uiElemScale) * 0.5

        s.font.draw(text, handlePos - size, newColor(0, 0, 0), s.fontMult * uiElemScale, fg = some(false))

proc lerp*(a, b: float, pc: float32): float =
  return a + (b - a) * pc

method update*(s: UISlider, parentRect: Rect, mousePos: Vector2,
    dt: float32, active: bool) =
  s.value = clamp(s.value, 0, 1)

  if s.isActive and active:
    s.valueVis = lerp(s.valueVis, s.value, clamp(dt * s.smooth, 0, 1))
  else:
    s.valueVis = s.value

method drag*(e: UISlider, button: int, done: bool) =
  e.value = e.tmpVal
  if e.update != nil:
    e.update(e.value)
  if done:
    if e.release != nil:
      e.release(e.value)

method scroll*(e: UISlider, offset: Vector2) =
  if e.vertical:
    e.value += e.scrollSensitivity * offset.y
  else:
    e.value += e.scrollSensitivity * offset.x
  e.value = clamp(e.value, 0, 1)
  if e.update != nil:
    e.update(e.value)

method navigate*(s: UISlider, dir: UIDir, parent: Rect): bool =
  if not s.focused:
    return false

  let bounds = s.bounds.toRect(parent)
  case dir:
    of UIRight:
      s.value += 0.05
      if s.update != nil:
        s.update(s.value)
      return true
    of UILeft:
      s.value -= 0.05
      if s.update != nil:
        s.update(s.value)
      return true
    else:
      return false

method focusable*(b: UISlider): bool =
  ## returns true if you can focus the element
  return true #not(b.isDisabled != nil and b.isDisabled())

method center*(e: UISlider, parent: Rect): Vector2 =
  ## returns true if you can focus the element
  return e.bounds.toRect(parent).location + newVector2(
    e.bounds.toRect(parent).size.x * e.value,
    e.bounds.toRect(parent).size.y * 1.0
  )
