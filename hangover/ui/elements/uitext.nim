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
    no_auto*: bool

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
    let
      base_text_size = t.font.sizeText(t.text.value)
      max_scale = min(
        bounds.width / base_text_size.x * 0.9,
        bounds.height / base_text_size.y * 0.9,
      )
      text_scale = if t.no_auto:
                     t.fontMult * uiElemScale
                   else:
                     min(
                       max_scale,
                       t.fontMult * uiElemScale,
                     )
      size = sizeText(t.font, t.text.value, text_scale)
    if size.x < bounds.width:
      var posx: float32 = bounds.x
      case t.align:
        of ACenter:
          posx = bounds.x + (bounds.width - size.x) / 2
        of ARight:
          posx = bounds.x + bounds.width - size.x
        else: discard
      t.font.draw(t.text.value, newVector2(posx, posy), t.color.value, text_scale, wrap = bounds.width)
      return

    var last = "..."
    for i in 0..t.text.value.high:
      var text = t.text.value[0..i] & "..."
      var size = sizeText(t.font, text, t.fontMult * uiElemScale).x
      if size > bounds.width:
        let
          base_text_size = t.font.sizeText(last)
          max_scale = min(
            bounds.width / base_text_size.x * 0.9,
            bounds.height / base_text_size.y * 0.9,
          )
          text_scale = if t.no_auto:
                         t.fontMult * uiElemScale
                       else:
                         min(
                           max_scale,
                           t.fontMult * uiElemScale,
                         )
        var posx: float32 = bounds.x
        t.font.draw(last, newVector2(posx, posy), t.color.value, text_scale, wrap = bounds.width)
        return
      last = text
    return

  let all_lines = t.text.value.split("\n")

  var line = 0
  for text in all_lines:
    let
      base_text_size = t.font.sizeText(text)
      max_scale = min(
        bounds.width / base_text_size.x * 0.9,
        (bounds.height / all_lines.len.float32) / base_text_size.y * 0.9,
      )
      text_scale = if t.no_auto:
                     t.fontMult * uiElemScale
                   else:
                     min(
                       max_scale,
                       t.fontMult * uiElemScale,
                     )

    var posx: float32 = bounds.x
    case t.align:
      of ACenter:
        posx = bounds.x + (bounds.width - sizeText(t.font, text, text_scale).x) / 2
      of ARight:
        posx = bounds.x + bounds.width - sizeText(t.font, text, text_scale).x
      else: discard

    posx = max(posx, bounds.x)
    t.font.draw(text, newVector2(posx, posy), t.color.value, text_scale, wrap = bounds.width)
    posy += t.font.sizeText(text, text_scale, wrap = bounds.width).y
