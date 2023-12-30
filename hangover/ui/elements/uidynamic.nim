import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/elements/uigroup
import hangover/ui/types/uisprite
import hangover/core/logging
import sugar

#TODO: comment

type
  UIDynamic* = ref object of UIGroup
    dynamicUpdate*: () -> bool
    dynamicGenerate*: (e: UIDynamic) -> seq[UIElement]

proc newUIDynamic*(bounds: UIRectangle): UIDynamic =
  result = UIDynamic()
  result.isActive = true
  result.bounds = bounds

method update*(d: UIDynamic, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not d.isActive:
    return
  if d.dynamicUpdate != nil and d.dynamicUpdate():
    d.elements = d.dynamicGenerate(d)
    if d.focused:
      d.focus(false)
      d.focus(true)
  let bounds = d.bounds.toRect(parentRect)
  for i in 0..<d.elements.len:
    d.elements[i].update(bounds, mousePos, dt)
