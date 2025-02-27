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

eventUpdateLineEnter.listen do (text: string) -> bool:
  tmpText = text

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

method click*(e: UIInput, button: int, key: bool) =
  if not e.focused: return
  if not e.active:
    tmpText = ""

    eventStartLineEnter.send
    eventSetLineEnter.send e.text

    e.active = true
  else:
    eventStopLineEnter.send
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
    e.font.draw(
      text,
      newVector2(posx, posy),
      newColor(0, 0, 0),
      e.fontMult * uiElemScale,
      contrast = ContrastEntry(mode: fg),
    )
  elif (e.hint != ""):
    let
      text = e.hint
      h: float32 = e.font.size.float32 * e.fontMult * uiElemScale
      posy: float32 = bounds.y + ((bounds.height - h) / 2)

    var
      posx: float32 = bounds.x + (bounds.width - sizeText(e.font, text, e.fontMult * uiElemScale).x) / 2
    e.font.draw(
      text,
      newVector2(posx, posy),
      newColor(0, 0, 0, 150),
      e.fontMult * uiElemScale,
      contrast = ContrastEntry(mode: fg),
    )
    if e.active:
      posx = bounds.x + (bounds.width - sizeText(e.font, "|", e.fontMult * uiElemScale).x) / 2
      e.font.draw(
        "|",
        newVector2(posx, posy),
        newColor(0, 0, 0),
        e.fontMult * uiElemScale,
        contrast = ContrastEntry(mode: fg),
      )

method propagate*(i: UIInput): bool =
  if not i.isActive:
    if i.active:
      eventStopLineEnter.send()
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
