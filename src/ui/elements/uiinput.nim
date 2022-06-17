import core/types/vector2
import core/types/point
import core/types/color
import core/types/rect
import core/types/font
import core/events
import ui/elements/uielement
import ui/types/uisprite

import sugar

type
  UIInput* = ref object of UIElement
    text*: string
    update*: (string) -> string
    hint*: string
    font*: ptr Font
    active*: bool

var tmpText = ""

proc onKey*(data: pointer): bool =
  var c = cast[ptr string](data)[]
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

method checkHover*(e: UIInput, parentRect: Rect, mousePos: Vector2): bool =
  e.focused = false
  if not e.isActive:
    return false
  if e.isDisabled != nil and e.isDisabled():
    return false

  var bounds = e.bounds.toRect(parentRect)
  if (bounds.x < mousePos.x and bounds.x +
          bounds.width > mousePos.x) and
      (bounds.y < mousePos.y and bounds.y +
              bounds.height > mousePos.y):
    e.focused = true
    return true

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
  var bounds = e.bounds.toRect(parentRect)
  if (e.text != ""):
    var text = e.text
    if e.active: text &= "|"
    var h: float32 = sizeText(e.font[], e.text).y
    var posy: float32 = bounds.y + ((bounds.height - h) / 2)
    var posx: float32 = bounds.x + (bounds.width - sizeText(e.font[],
        e.text).x) / 2
    e.font[].draw(text, newPoint(posx.cint, posy.cint), newColor(0, 0, 0))
    posy += sizeText(e.font[], text).y
  elif (e.hint != ""):
    var text = e.hint
    var h: float32 = sizeText(e.font[], text).y
    var posy: float32 = bounds.y + ((bounds.height - h) / 2)
    var posx: float32 = bounds.x + (bounds.width - sizeText(e.font[], text).x) / 2
    e.font[].draw(text, newPoint(posx.cint, posy.cint), newColor(0, 0, 0, 150))
    if e.active:
      posx = bounds.x + (bounds.width - sizeText(e.font[], "|").x) / 2
      e.font[].draw("|", newPoint(posx.cint, posy.cint), newColor(0, 0, 0))
    posy += sizeText(e.font[], text).y

method update*(b: var UIInput, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool =
  if not b.isActive:
    if b.active:
      sendEvent(EVENT_STOP_LINE_ENTER, nil)
      b.active = false
    return false
  var bounds = b.bounds.toRect(parentRect)

  if b.active and tmpText != "":
    if b.update != nil:
      b.text = b.update(tmpText)
    else:
      b.text = tmpText
    tmpText = ""

  return false
