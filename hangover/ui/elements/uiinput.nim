import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/events
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import sugar

#TODO: comment

type
  UIInput* = ref object of UIElement
    text*: string
    update*: (string) -> string
    hint*: string
    font*: ptr Font
    fontMult*: float32
    active*: bool

var tmpText = ""

proc onKey*(data: pointer): bool =
  let c = cast[ptr string](data)[]
  tmpText = c

createListener(EVENT_LINE_ENTER, onKey)

proc newUIInput*(font: var Font, bounds: UIRectangle, hint = "",
    disable: () -> bool = nil): UIInput =
  var r = UIInput()

  r.font = addr font

  r.isActive = true
  r.bounds = bounds
  r.hint = hint
  r.isDisabled = disable

  return r

method checkHover*(e: UIInput, parentRect: Rect, mousePos: Vector2) =
  e.focused = false
  if not e.isActive:
    return
  if e.isDisabled != nil and e.isDisabled():
    return

  let bounds = e.bounds.toRect(parentRect)
  if (bounds.x < mousePos.x and bounds.x +
          bounds.width > mousePos.x) and
      (bounds.y < mousePos.y and bounds.y +
              bounds.height > mousePos.y):
    e.focused = true

method click*(e: UIInput, button: int) =
  if not e.focused: return
  if not e.active:
    sendEvent(EVENT_START_LINE_ENTER, nil)
    sendEvent(EVENT_SET_LINE_TEXT, addr e.text)
    e.active = true
  else:
    sendEvent(EVENT_STOP_LINE_ENTER, nil)
    e.active = false

method draw*(e: UIInput, parentRect: Rect) =
  if not e.isActive:
    return
  let bounds = e.bounds.toRect(parentRect)
  if (e.text != ""):
    var text = e.text
    if e.active: text &= "|"
    let
      h: float32 = sizeText(e.font[], e.text, e.fontMult * uiElemScale).y
      posx: float32 = bounds.x + (bounds.width - sizeText(e.font[],
        e.text, e.fontMult * uiElemScale).x) / 2
    var
      posy: float32 = bounds.y + ((bounds.height - h) / 2)
    e.font[].draw(text, newPoint(posx.cint, posy.cint), newColor(0, 0, 0), e.fontMult * uiElemScale)
    posy += sizeText(e.font[], text, e.fontMult * uiElemScale).y
  elif (e.hint != ""):
    let
      text = e.hint
      h: float32 = sizeText(e.font[], text, e.fontMult * uiElemScale).y
    var
      posy: float32 = bounds.y + ((bounds.height - h) / 2)
      posx: float32 = bounds.x + (bounds.width - sizeText(e.font[], text, e.fontMult * uiElemScale).x) / 2
    e.font[].draw(text, newPoint(posx.cint, posy.cint), newColor(0, 0, 0, 150), e.fontMult * uiElemScale)
    if e.active:
      posx = bounds.x + (bounds.width - sizeText(e.font[], "|", e.fontMult * uiElemScale).x) / 2
      e.font[].draw("|", newPoint(posx.cint, posy.cint), newColor(0, 0, 0), e.fontMult * uiElemScale)
    posy += sizeText(e.font[], text, e.fontMult * uiElemScale).y

method update*(b: UIInput, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not b.isActive:
    if b.active:
      sendEvent(EVENT_STOP_LINE_ENTER, nil)
      b.active = false
    return
  let bounds = b.bounds.toRect(parentRect)

  if b.active:
    if b.update != nil:
      b.text = b.update(tmpText)
    else:
      b.text = tmpText

method focusable*(e: UIInput): bool =
  return not(e.isDisabled != nil and e.isDisabled())
