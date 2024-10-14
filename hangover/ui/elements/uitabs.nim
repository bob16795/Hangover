import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/elements/uigroup
import hangover/ui/types/uisprite
import hangover/ui/types/uifield
import hangover/core/logging
import hangover/rendering/shapes
import options
import sugar

type
  UITabs* = ref object of UIGroup
    active_tab*: UIField[int]

method checkHover*(t: UITabs, parentRect: Rect, mousePos: Vector2) =
  let bounds = t.bounds.toRect(parentRect)
  t.elements[t.active_tab.value].checkHover(bounds, mousePos)

method click*(t: UITabs, button: int, key: bool) =
  t.elements[t.active_tab.value].click(button, key)

method draw*(t: UITabs, parentRect: Rect) =
  let bounds = t.bounds.toRect(parentRect)
  t.elements[t.active_tab.value].draw(bounds)

method update*(t: UITabs, parentRect: Rect, mousePos: Vector2,
    dt: float32, active: bool) =
  let bounds = t.bounds.toRect(parentRect)

  for ei in 0..<t.elements.len:
    t.elements[ei].update(bounds, mousePos, dt, active and t.active_tab.value == ei)
  
  t.focused = t.elements[t.active_tab.value].focused


method scroll*(t: UITabs, offset: Vector2) =
  t.elements[t.active_tab.value].scroll(offset)

method drag*(t: UITabs, button: int, done: bool) =
  t.elements[t.active_tab.value].drag(button, done)

method propagatee*(t: UITabs): bool =
  t.elements[t.active_tab.value].propagate()

method navigate*(t: UITabs, dir: UIDir, parent: Rect): bool =
  t.elements[t.active_tab.value].navigate(dir, parent)

method focus*(t: UITabs, focus: bool) =
  ## returns true if you can focus the element
  t.elements[t.active_tab.value].focus(focus)

method center*(t: UITabs, parent: Rect): Vector2 =
  let bounds = t.bounds.toRect(parent)
  return t.elements[t.active_tab.value].center(bounds)

method updateTooltip*(t: UITabs, dt: float32) =
  t.elements[t.active_tab.value].updateTooltip(dt)

method isTooltip*(t: UITabs): bool =
  t.elements[t.active_tab.value].isTooltip()

method drawTooltip*(t: UITabs, mousePos: Vector2, size: Point) =
  t.elements[t.active_tab.value].drawTooltip(mousePos, size)

method drawDebug*(t: UITabs, parentRect: Rect) =
  if not t.isActive: return

  let bounds = t.bounds.toRect(parentRect)
  t.elements[t.active_tab.value].drawDebug(bounds)

  drawRectOutline(
    bounds,
    1,
    COLOR_YELLOW,
  )

method getElems*(t: UITabs): seq[UIElement] =
  t.elements[t.active_tab.value].getElems()