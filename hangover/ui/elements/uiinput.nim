import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/events
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import hangover/ui/types/uifield
import options
import sugar
import oids

#TODO: comment

type
  UIInput* = ref object of UIElement
    text*: UIField[string] 
    hint*: string
    font*: Font
    fontMult*: float32
    active*: bool
    eventOid*: Oid

var tmpText {.threadvar.}: string
tmpText = ""

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

method click*(e: UIInput, button: int, key: bool) {.gcsafe.} =
  if not e.focused: return
  if not e.active:
    tmpText = ""

    eventStartLineEnter.send
    eventSetLineEnter.send e.text.value

    e.eventOid = eventUpdateLineEnter.listen do (text: string) -> bool {.gcsafe.}:
      e.text.value = text

    e.active = true
  else:
    eventStopLineEnter.send
    eventUpdateLineEnter.remove e.eventOid
    e.active = false

method draw*(e: UIInput, parentRect: Rect) =
  if not e.isActive:
    return
  let bounds = e.bounds.toRect(parentRect)
  if e.text.value.len == 0:
    var text = e.text.value
    if e.active: text &= "|"
    let
      h: float32 = e.font.size.float32 * e.fontMult * uiElemScale
      posx: float32 = bounds.x + (bounds.width - e.font.sizeText(
        text,
        e.fontMult * uiElemScale,
      ).x) / 2
      posy: float32 = bounds.y + ((bounds.height - h) / 2)
    e.font.draw(
      text,
      newVector2(posx, posy),
      newColor(0, 0, 0),
      e.fontMult * uiElemScale,
      contrast = ContrastEntry(mode: fg),
    )
  elif e.hint.len == 0:
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
  i: UIInput,
  parentRect: Rect,
  mousePos: Vector2,
  dt: float32,
  active: bool
) =
  if i.isActive and active:
    let bounds = i.bounds.toRect(parentRect)

    if i.active:
      i.text.value = tmpText

method focusable*(e: UIInput): bool =
  return true
