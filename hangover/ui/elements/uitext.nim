import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import strutils

#TODO: comment

type
  UITextAlign* = enum
    ACenter,
    ALeft,
    ARight
  UIText* = ref object of UIElement
    font*: Font
    fontMult*: float32
    text*: UIField[string]
    inactive*: bool
    underline*: bool
    align*: UITextAlign
    color*: UIField[Color]
    cutoff*: bool

method draw*(t: UIText, parentRect: Rect) =
  if not t.isActive: return
  if t.text.value == "": return

  let bounds = t.bounds.toRect(parentRect)
  var h: float32 = 0
  for text in t.text.value.split("\n"):
    h += t.font.size.float32 * t.fontMult * uiElemScale
  var posy: float32 = bounds.y + (bounds.height - h) / 2
  posy = max(posy, bounds.y)

  if "\n" notin t.text.value and t.cutoff:
    let size = sizeText(t.font, t.text.value, t.fontMult * uiElemScale)
    if size.x < bounds.width:
      var posx: float32 = bounds.x
      case t.align:
        of ACenter:
          posx = bounds.x + (bounds.width - size.x) / 2
        of ARight:
          posx = bounds.x + bounds.width - size.x
        else: discard
      t.font.draw(t.text.value, newVector2(posx, posy), t.color.value, t.fontMult * uiElemScale, wrap = bounds.width)
      return

    var last = "..."
    for i in 0..t.text.value.high:
      var text = t.text.value[0..i] & "..."
      var size = sizeText(t.font, text, t.fontMult * uiElemScale).x
      if size > bounds.width:
        var posx: float32 = bounds.x
        t.font.draw(last, newVector2(posx, posy), t.color.value, t.fontMult * uiElemScale, wrap = bounds.width)
        return
      last = text
    return

  var line = 0
  for text in t.text.value.split("\n"):
    var posx: float32 = bounds.x
    case t.align:
      of ACenter:
        posx = bounds.x + (bounds.width - sizeText(t.font, text, t.fontMult * uiElemScale).x) / 2
      of ARight:
        posx = bounds.x + bounds.width - sizeText(t.font, text, t.fontMult * uiElemScale).x
      else: discard
    posx = max(posx, bounds.x)
    t.font.draw(text, newVector2(posx, posy), t.color.value, t.fontMult * uiElemScale, wrap = bounds.width)
    posy += t.font.sizeText(text, t.fontMult * uiElemScale, wrap = bounds.width).y
