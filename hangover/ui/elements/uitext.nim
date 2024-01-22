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
    text*: ref string
    inactive*: bool
    update*: UIUpdate
    align*: UITextAlign
    underline*: bool
    color*: Color

proc newUIText*(font: Font, bounds: UIRectangle, update: UIUpdate,
    align = ACenter, ina: bool = false, ul: bool = false, color = newColor(0, 0, 0, 255)): UIText =
  result = UIText()

  result.isActive = true
  result.font = font
  result.bounds = bounds
  result.update = update
  result.align = align
  result.inactive = ina
  result.underline = ul
  result.color = color
  result.text = string.new()

method draw*(t: UIText, parentRect: Rect) =
  if not t.isActive:
    return
  if (t.text == nil or t.text[] == ""): return
  let bounds = t.bounds.toRect(parentRect)
  var h: float32 = 0
  for text in t.text[].split("\n"):
    h += t.font.size.float32 * t.fontMult * uiElemScale
  var posy: float32 = bounds.y + (bounds.height - h) / 2
  posy = max(posy, bounds.y)
  for text in t.text[].split("\n"):
    var posx: float32 = bounds.x
    case t.align:
      of ACenter:
        posx = bounds.x + (bounds.width - sizeText(t.font, text, t.fontMult * uiElemScale).x) / 2
      of ARight:
        posx = bounds.x + bounds.width - sizeText(t.font, text, t.fontMult * uiElemScale).x
      else: discard
    posx = max(posx, bounds.x)
    t.font.draw(text, newPoint(posx.cint, posy.cint), t.color, t.fontMult * uiElemScale, wrap = bounds.width)
    posy += t.font.size.float32 * t.fontMult * uiElemScale

method update*(t: UIText, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not t.isActive:
    return
  let bounds = t.bounds.toRect(parentRect)
  if t.update != nil:
    if t.text == nil:
        t.text = string.new()
    t.text[] = t.update()
