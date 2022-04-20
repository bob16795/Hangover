import sugar
import core/types/rect
import core/types/texture
import core/types/vector2
import rendering/sprite
import uirectangle
import uisprite

export uirectangle
export uisprite
export texture
export sprite

type
  UIAction* = (i: int) -> void
  UIUpdate* = () -> string
  UITextAlign* = enum
    ALeft,
    ARight,
    ACenter
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
  # if not e.isActive:
  #   if e.tween.valid:
  #     e.tween.reset()
  #   return false
  # if e.tween.valid:
  #   e.bounds = e.tween.val(dt)
  return false

method draw*(element: UIElement, parentRect: Rect) {.base.} =
  if not element.isActive:
    return
