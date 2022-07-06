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

# TODO: cleanup return bools

type
  UIAction* = (i: int) -> void
    ## a action called when a button is pressed
  UIUpdate* = () -> string
    ## gets the text to update a text element
  UIElement* = ref object of RootObj
    ## a generic ui element does nothing
    focused*: bool ## wether the element is focused
    isActive*: bool ## if the element is active
    bounds*: UIRectangle ## the target bounds
    isDisabled*: () -> bool ## checks if the element is disabled

method checkHover*(e: UIElement, parentRect: Rect,
    mousePos: Vector2): bool {.base.} =
  ## updates the element on a mouse move event
  echo "check hover not implemented for element"

method update*(e: var UIElement, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool {.base.} =
  ## updates the element on a frame
  echo "update is not implemented for element"

method click*(e: UIElement, button: int) {.base.} =
  ## processes a click event
  discard

method drag*(e: UIElement, button: int) {.base.} =
  ## process a move event when the mouse is pressed
  discard

method draw*(e: UIElement, parentRect: Rect) {.base.} =
  ## draws the element
  echo "draw is not implemented for element"
