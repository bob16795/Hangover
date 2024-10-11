import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import hangover/core/logging
import hangover/rendering/shapes
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

method add*(g: var UIGroup, e: UIElement) =
  g.elements.add(e)

method clear*(g: var UIGroup) =
  g.elements = @[]

method checkHover*(g: UIGroup, parentRect: Rect, mousePos: Vector2) =
  g.focused = false
  if not g.isActive:
    return
  if g.disabled.value:
    return

  let bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].checkHover(bounds, mousePos)

  for i in 0..<g.elements.len:
    if g.elements[i].focused:
      g.focused = true

method click*(g: UIGroup, button: int, key: bool) =
  for i in 0..<g.elements.len:
    g.elements[i].click(button, key)
    if not key and g.elements[i].propagate():
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

  var postpone: seq[UIElement]

  for i in 0..<g.elements.len:
    if g.elements[i].focused:
      postpone &= g.elements[i]
    else:
      g.elements[i].draw(bounds)

  for p in postpone:
    p.draw(bounds)

  textureScissor = oldScissor

method update*(g: UIGroup, parentRect: Rect, mousePos: Vector2,
    dt: float32, active: bool) =
  let bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].update(bounds, mousePos, dt, g.isActive and active)

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
  return false

method navigate*(g: UIGroup, dir: UIDir, parent: Rect): bool =
  let bounds = g.bounds.toRect(parent)

  case dir:
    of UIPrev, UINext:
      for e in g.elements:
        let tmp = e.navigate(dir, bounds)
        result = result or tmp
    else: discard

method focus*(g: UIGroup, focus: bool) =
  ## returns true if you can focus the element
  for e in g.elements:
    if not e.isActive: continue

    if e.focusable():
      e.focus(focus)
      if focus and e.focused:
        g.focused = true
        return
    else:
      e.focus(false)
  g.focused = false

method center*(g: UIGroup, parent: Rect): Vector2 =
  let bounds = g.bounds.toRect(parent)

  ## returns true if you can focus the element
  for e in g.elements:
    if not e.isActive: continue

    if e.focused:
      return e.center(bounds)
  return bounds.center

method updateTooltip*(g: UIGroup, dt: float32) =
  for e in g.elements:
    e.updateTooltip(dt)

method isTooltip*(g: UIGroup): bool =
  for e in g.elements:
    if e.isTooltip:
      return true

method drawTooltip*(g: UIGroup, mousePos: Vector2, size: Point) =
  for e in g.elements:
    e.drawTooltip(mousePos, size)

method updateCenter*(g: UIGroup, parentRect: Rect) =
  let bounds = g.bounds.toRect(parentRect)

  for e in g.elements:
    e.updateCenter(bounds)

  g.navPoint = bounds.location

method drawDebug*(g: UIGroup, parentRect: Rect) =
  var bounds = g.bounds.toRect(parentRect)

  drawRectOutline(
    bounds,
    5,
    COLOR_RED,
  )

  for e in g.elements:
    if e.isActive:
      e.drawDebug(bounds)

method getElems*(g: UIGroup): seq[UIElement] =
  if not g.isActive:
    return
  for e in g.elements:
    result &= e.getElems()

method propagate*(g: UIGroup): bool =
  for e in g.elements:
    if e.propagate():
      result = true

method moveCenter*(g: var UIGroup, diff: Vector2) =
  ## returns true if you can focus the element
  g.bounds.lastCenter += diff

  for e in 0..<len g.elements:
    g.elements[e].moveCenter(diff)