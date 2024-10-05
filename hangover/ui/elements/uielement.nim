import sugar
import hangover/core/types/rect
import hangover/core/types/texture
import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/rendering/sprite
import hangover/rendering/shapes
import hangover/ui/types/uirectangle
import hangover/ui/types/uisprite
import hangover/ui/types/uitooltip
import hangover/core/logging
import hangover/ui/types/uifield

export uirectangle
export uisprite
export texture
export uifield
export sprite

# TODO: cleanup return bools

var
  uiElemScale*: float32 = 1

type
  UIAction* = (i: int) -> void
    ## a action called when a button is pressed
  UIUpdate* = () -> string
    ## gets the text to update a text element
  UIDir* = enum
    UISelect
    UIScrollUp
    UIScrollDown
    UIPrev
    UINext
    UIUp
    UIDown
    UILeft
    UIRight

  UIElement* = ref object of RootObj
    ## a generic ui element does nothing
    focused*: bool          ## wether the element is focused
    isActive*: bool         ## if the element is active
    bounds*: UIRectangle    ## the target bounds
    disabled*: UIField[bool]
    tooltip*: UIToolTip
    tooltipTimer*: float32
    neverFocus*: bool
    navPoint*: Vector2
    navCenter*: Vector2

    focusDir*: array[UIUp..UIRight, UIElement]

method checkHover*(e: UIElement, parentRect: Rect, mousePos: Vector2) {.base.} =
  ## updates the element on a mouse move event
  discard

method update*(e: UIElement, parentRect: Rect, mousePos: Vector2,
    dt: float32, active: bool) {.base.} =
  ## updates the element on a frame
  discard

method click*(e: UIElement, button: int) {.base.} =
  ## processes a click event
  discard

method drag*(e: UIElement, button: int, done: bool) {.base.} =
  ## process a move event when the mouse is pressed
  discard

method draw*(e: UIElement, parentRect: Rect) {.base.} =
  ## draws the element
  discard

method scroll*(e: UIElement, offset: Vector2) {.base.} =
  ## draws the element
  discard

method focus*(e: UIElement, focus: bool) {.base.} =
  ## returns true if you can focus the element
  e.focused = focus

method moveCenter*(e: var UIElement, diff: Vector2) {.base.} =
  ## returns true if you can focus the element
  e.bounds.lastCenter += diff

method `active=`*(e: UIElement, value: bool) {.base.} =
  ## hides / shows the element
  e.isActive = value
  if not value:
    e.focus(false)

method focusable*(e: UIElement): bool {.base.} =
  ## returns true if you can focus the element
  false

method navigate*(e: UIElement, dir: UIDir, parent: Rect): bool {.base.} =
  ## navigates to the next elem
  return false

method center*(e: UIElement, parent: Rect): Vector2 {.base.} =
  ## returns true if you can focus the element
  return e.bounds.lastCenter

method updateTooltip*(e: UIElement, dt: float32) {.base.} =
  if e.tooltip != nil:
    if e.focused:
      e.tooltipTimer += dt
    else:
      e.tooltipTimer = 0.0

method isTooltip*(e: UIElement): bool {.base.} =
  return e.isActive and e.tooltip != nil and e.tooltipTimer > 0.25

method drawTooltip*(e: UIElement, mousePos: Vector2, size: Point) {.base.} =
  if e.isTooltip:
    e.tooltip.draw(mousePos, size)

method getElems*(e: UIElement): seq[UIElement] {.base.} =
  if not e.isActive:
    return
  if e.focusable:
    result &= e

method propagate*(e: UIElement): bool {.base.} =
  return e.focused

method updateCenter*(e: UIElement, parentRect: Rect) {.base.} =
  e.navPoint = e.bounds.toRect(parentRect).location
  e.navCenter = e.bounds.toRect(parentRect).center

method drawDebug*(e: UIElement, parentRect: Rect) {.base.} =
  ## draws the element
  if not e.focusable:
    return
  let bounds = e.bounds.toRect(parentRect)

  let color = if e.focused:
    COLOR_RED
  else:
    COLOR_BLUE
  
  drawRectOutline(
    bounds,
    5,
    color,
  )

  for f in e.focusDir:
    if f != nil:
      if not f.focused:
        drawLine(e.navCenter, f.navCenter, 5, color)
