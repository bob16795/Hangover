import sugar
import core/types/rect
import core/types/texture
import core/types/vector2
import rendering/sprite
import ui/types/uirectangle
import ui/types/uisprite

export uirectangle
export uisprite
export texture
export sprite

type
  UIAction* = (i: int) -> void
  UIUpdate* = () -> string
  UIElement* = ref object of RootObj
    focused*: bool
    isActive*: bool
    bounds*: UIRectangle
    isDisabled*: () -> bool

method checkHover*(e: UIElement, parentRect: Rect,
    mousePos: Vector2): bool {.base.} =
  if not e.isActive:
    return false

method update*(e: var UIElement, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool {.base.} =
  e.focused = false
  # if not e.isActive:
  #   if e.tween.valid:
  #     e.tween.reset()
  #   return false
  # if e.tween.valid:
  #   e.bounds = e.tween.val(dt)
  return false

method click*(e: UIElement, button: int) {.base.} =
  discard

method draw*(e: UIElement, parentRect: Rect) {.base.} =
  if not e.isActive:
    return
