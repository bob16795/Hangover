import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/events
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import options
import sugar

#TODO: comment

type
  UIInput* = ref object of UIElement
    getText*: () -> string
    setText*: (string) -> void
    hint*: string
    font*: Font
    fontMult*: float32
    active*: bool

var tmpText = ""

proc text*(i: UIInput): string =
  i.getText()

proc `text=`*(i: UIInput, text: string) =
  i.setText(text)

proc onKey*(data: pointer): bool =
  let c = cast[ptr string](data)[]
  tmpText = c

createListener(EVENT_LINE_ENTER, onKey)

method checkHover*(e: UIInput, parentRect: Rect, mousePos: Vector2) =
  e.focused = false
  if not e.isActive:
    return
  if e.disabled.value:
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
    let line_text = e.text

    tmpText = ""
    sendEvent(EVENT_START_LINE_ENTER, nil)
    sendEvent(EVENT_SET_LINE_TEXT, addr line_text)
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
      h: float32 = e.font.size.float32 * e.fontMult * uiElemScale
      posx: float32 = bounds.x + (bounds.width - sizeText(e.font,
        e.text, e.fontMult * uiElemScale).x) / 2
      posy: float32 = bounds.y + ((bounds.height - h) / 2)
    e.font.draw(text, newVector2(posx, posy), newColor(0, 0, 0), e.fontMult * uiElemScale, fg = some(true))
  elif (e.hint != ""):
    let
      text = e.hint
      h: float32 = e.font.size.float32 * e.fontMult * uiElemScale
      posy: float32 = bounds.y + ((bounds.height - h) / 2)

    var
      posx: float32 = bounds.x + (bounds.width - sizeText(e.font, text, e.fontMult * uiElemScale).x) / 2
    e.font.draw(text, newVector2(posx, posy), newColor(0, 0, 0, 150), e.fontMult * uiElemScale, fg = some(true))
    if e.active:
      posx = bounds.x + (bounds.width - sizeText(e.font, "|", e.fontMult * uiElemScale).x) / 2
      e.font.draw("|", newVector2(posx, posy), newColor(0, 0, 0), e.fontMult * uiElemScale, fg = some(true))

method propagate*(i: UIInput): bool =
  if not i.isActive:
    if i.active:
      sendEvent(EVENT_STOP_LINE_ENTER, nil)
      i.active = false
  return i.focused

method update*(
  b: UIInput,
  parentRect: Rect,
  mousePos: Vector2,
  dt: float32,
  active: bool
) =
  if b.isActive and active:
    let bounds = b.bounds.toRect(parentRect)

    if b.active:
      b.text = tmpText

method focusable*(e: UIInput): bool =
  return true
