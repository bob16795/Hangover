import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import hangover/core/logging
import options
import algorithm
import sugar

#TODO: comment

type
  UIGroup* = ref object of UIElement
    elements*: seq[UIElement]
    hasPopupAbove*: bool
    dragProc*: proc(done: bool)
    scissor*: bool

proc newUIGroup*(bounds: UIRectangle): UIGroup =
  result = UIGroup()
  result.isActive = true
  result.bounds = bounds

proc add*(g: var UIGroup, e: UIElement) =
  g.elements.add(e)

proc clear*(g: var UIGroup) =
  g.elements = @[]

method checkHover*(g: UIGroup, parentRect: Rect, mousePos: Vector2) =
  g.focused = false
  if not g.isActive:
    return
  if g.isDisabled != nil and g.isDisabled():
    return

  let bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].checkHover(bounds, mousePos)
    if g.elements[i].focused:
      g.focused = true

method click*(g: UIGroup, button: int) =
  for i in 0..<g.elements.len:
    if g.elements[i].focused:
      g.elements[i].click(button)
      capture i:
        g.dragProc = proc(done: bool) = g.elements[i].drag(button, done)

method draw*(g: UIGroup, parentRect: Rect) =
  if not g.isActive:
    return
  let
    bounds = g.bounds.toRect(parentRect)
    oldScissor = textureScissor

  if g.scissor:
    textureScissor = bounds.scale(uiScaleMult)

  var postpone: Option[UIElement]

  for i in 0..<g.elements.len:
    if g.elements[i].focused:
      postpone = some(g.elements[i])
    else:
      g.elements[i].draw(bounds)

  if postpone.is_some():
    postpone.get().draw(bounds)

  textureScissor = oldScissor

method update*(g: UIGroup, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not g.isActive:
    return
  let bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].update(bounds, mousePos, dt)

method drag*(g: UIGroup, button: int, done: bool) =
  if g.dragProc != nil:
    g.dragProc(done)

method scroll*(g: UIGroup, offset: Vector2) =
  for i in 0..<g.elements.len:
    g.elements[i].scroll(offset)

method `active=`*(g: UIGroup, value: bool) =
  g.isActive = value
  if not value:
    g.focus(false)
  for e in g.elements:
    e.active = value

method focusable*(g: UIGroup): bool =
  for e in g.elements:
    if e.focusable:
      return true

method navigate*(g: UIGroup, dir: UIDir, parent: Rect): bool =
  if not g.focused:
    return false

  let bounds = g.bounds.toRect(parent)

  case dir:
    of UISelect:
      return false
    of UINext, UIDown, UIRight:
      var focusNext = false

      for e in g.elements:
        if not e.isActive: continue

        if focusNext:
          if e.focusable():
            e.focus(true)
            return true

        if e.navigate(dir, bounds):
          if e.focused: return true
          focusNext = true

      if focusNext: g.focus(false)
      return true
    of UIPrev, UIUp, UILeft:
      var focusNext = false

      for e in g.elements.reversed():
        if not e.isActive: continue

        if focusNext:
          if e.focusable():
            e.focus(true)
            return true

        if e.navigate(dir, bounds):
          if e.focused: return true
          focusNext = true

      if focusNext: g.focus(false)
      return true
    else: discard

method focus*(g: UIGroup, focus: bool) =
  ## returns true if you can focus the element
  g.focused = focus
  for e in g.elements:
    if not e.isActive: continue

    if e.focusable():
      e.focus(focus)
      if focus:
        return

method center*(g: UIGroup, parent: Rect): Vector2 =
  let bounds = g.bounds.toRect(parent)

  ## returns true if you can focus the element
  for e in g.elements:
    if not e.isActive: continue

    if e.focused:
      return e.center(bounds)
