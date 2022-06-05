import core/types/vector2
import core/types/point
import core/types/color
import core/types/rect
import core/types/font
import ui/elements/uielement

import strutils

type
  UITextAlign* = enum
    ACenter,
    ALeft,
    ARight
  UIText* = ref object of UIElement
    font*: ptr Font
    text*: string
    inactive*: bool
    update*: UIUpdate
    align*: UITextAlign
    underline*: bool
    color*: Color

proc newUIText*(font: var Font, bounds: UIRectangle, update: UIUpdate,
    align = ACenter, ina: bool = false, ul: bool = false, color = newColor(0, 0, 0, 255)): UIText =
  result = UIText()

  result.isActive = true
  result.font = addr font
  result.bounds = bounds
  result.update = update
  result.align = align
  result.inactive = ina
  result.underline = ul
  result.color = color

method draw*(t: UIText, parentRect: Rect) =
  if not t.isActive:
    return
  if (t.text == ""): return
  var bounds = t.bounds.toRect(parentRect)
  var h: float32 = 0
  for text in t.text.split("\n"):
    h += t.font[].size.float32
  var posy: float32 = bounds.y + (bounds.height - h) / 2
  posy = max(posy, bounds.y)
  for text in t.text.split("\n"):
    var posx: float32 = bounds.x
    case t.align:
      of ACenter:
        posx = bounds.x + (bounds.width - sizeText(t.font[], text).x) / 2
      of ARight:
        posx = bounds.x + bounds.width - sizeText(t.font[], text).x
      else: discard
    posx = max(posx, bounds.x)
    t.font[].draw(text, newPoint(posx.cint, posy.cint), t.color)
    posy += t.font[].size.float32

method update*(t: var UIText, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool =
  if not t.isActive:
    return false
  var bounds = t.bounds.toRect(parentRect)
  if t.update != nil:
    t.text = t.update()
  return false
