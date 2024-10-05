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

    lastAct: bool

proc newUIDynamic*(bounds: UIRectangle): UIDynamic =
  result = UIDynamic()
  result.isActive = true
  result.bounds = bounds

method update*(d: UIDynamic, parentRect: Rect, mousePos: Vector2,
    dt: float32, active: bool) =
  if d.dynamicUpdate == nil or d.dynamicUpdate():
    d.elements = d.dynamicGenerate(d)
    if d.focused:
      d.focus(true)

  let bounds = d.bounds.toRect(parentRect)
  for i in 0..<d.elements.len:
    d.elements[i].update(bounds, mousePos, dt, active and d.isActive)

method draw*(d: UIDynamic, r: Rect) =
  if d.lastAct != d.isActive:
    d.elements = d.dynamicGenerate(d)
    if d.focused:
      d.focus(true)

    d.lastAct = d.isActive

  procCall d.UIGroup.draw(r)
