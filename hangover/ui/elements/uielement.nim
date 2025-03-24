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
  UIAction* = proc(i: int) {.gcsafe.}
    ## a action called when a button is pressed
  UIUpdate* = proc(): string {.gcsafe.}
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

  UIElement* {.acyclic.} = ref object of RootObj
    ## a generic ui element does nothing
    focused*: bool          ## wether the element is focused
    isActive*: bool = true  ## if the element is active
    bounds*: UIRectangle    ## the target bounds
    disabled*: UIField[bool]
    tooltip*: UIToolTip
    tooltipTimer*: float32
    neverFocus*: bool
    navPoint*: Vector2
    navCenter*: Vector2

    focusDir*: array[UIUp..UIRight, UIElement]

method checkHover*(e: UIElement, parentRect: Rect, mousePos: Vector2) {.base, gcsafe.} =
  ## updates the element on a mouse move event
  discard

method update*(e: UIElement, parentRect: Rect, mousePos: Vector2,
    dt: float32, active: bool) {.base, gcsafe.} =
  ## updates the element on a frame
  discard

method click*(e: UIElement, button: int, key: bool) {.base, gcsafe.} =
  ## processes a click event
  discard

method drag*(e: UIElement, button: int, done: bool) {.base, gcsafe.} =
  ## process a move event when the mouse is pressed
  discard

method draw*(e: UIElement, parentRect: Rect) {.base, gcsafe.} =
  ## draws the element
  discard

method scroll*(e: UIElement, offset: Vector2) {.base, gcsafe.} =
  ## draws the element
  discard

method focus*(e: UIElement, focus: bool) {.base, gcsafe.} =
  ## returns true if you can focus the element
  e.focused = focus

method moveCenter*(e: UIElement, diff: Vector2) {.base, gcsafe.} =
  ## returns true if you can focus the element
  e.bounds.lastCenter += diff

method `active=`*(e: UIElement, value: bool) {.base, gcsafe.} =
  ## hides / shows the element
  e.isActive = value
  if not value:
    e.focus(false)

method focusable*(e: UIElement): bool {.base, gcsafe.} =
  ## returns true if you can focus the element
  false

method navigate*(e: UIElement, dir: UIDir, parent: Rect): bool {.base, gcsafe.} =
  ## navigates to the next elem
  return false

method center*(e: UIElement, parent: Rect): Vector2 {.base, gcsafe.} =
  ## returns true if you can focus the element
  return e.bounds.lastCenter

method updateTooltip*(e: UIElement, dt: float32) {.base, gcsafe.} =
  if e.tooltip != nil:
    if e.focused:
      e.tooltipTimer += dt
    else:
      e.tooltipTimer = 0.0

method isTooltip*(e: UIElement): bool {.base, gcsafe.} =
  return e.isActive and e.tooltip != nil and e.tooltipTimer > 0.25

method drawTooltip*(e: UIElement, mousePos: Vector2, size: Point) {.base, gcsafe.} =
  if e.isTooltip:
    e.tooltip.draw(mousePos, size)

method getElems*(e: UIElement): seq[UIElement] {.base, gcsafe.} =
  if not e.isActive:
    return
  if e.focusable:
    result &= e

method propagate*(e: UIElement): bool {.base, gcsafe.} =
  return e.focused

method updateCenter*(e: UIElement, parentRect: Rect) {.base, gcsafe.} =
  e.navPoint = e.bounds.toRect(parentRect).location
  e.navCenter = e.bounds.toRect(parentRect).center

method drawDebug*(e: UIElement, parentRect: Rect) {.base, gcsafe.} =
  ## draws the element
  if not e.isActive: return
  if not e.focusable: return

  let bounds = e.bounds.toRect(parentRect)

  if e.focused:
    drawRectOutline(
      bounds,
      10,
      COLOR_BLUE,
    )

  drawRectOutline(
    bounds,
    5,
    COLOR_RED,
  )

