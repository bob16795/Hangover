import core/types/vector2
import core/types/rect
import core/events
import ui/uimanager
import ecs/genmacros
import ecs/entity
import ecs/component
import ecs/types
import core/templates
import rectcomponent

{.experimental: "codeReordering".}

component UIComponent:
  var
    element: UIElement
    mousePos: Vector2

    drag: UIElement
    last: int

  proc eventMouseMove(pos: tuple[x, y: float64]): bool =
    var rect = parent[RectComponentData]
    this.mousePos = newVector2(pos.x, pos.y)
    discard this.element.checkHover(newRect(rect.position, rect.size), this.mousePos)
    if this.drag != nil:
      this.drag.drag(this.last)

  proc eventMouseClick(btn: int): bool =
    this.last = btn
    sendEvent(EVENT_STOP_LINE_ENTER, nil)
    var active = this.element.isActive
    if this.element.focused:
      this.element.click(btn)
      this.drag = this.element
    var rect = parent[RectComponentData]
    var dest = newRect(rect.position, rect.size)
    return active and dest.contains(this.mousePos)

  proc eventMouseRelease(data: void): bool =
    this.drag = nil

  proc eventDrawUi(data: void): bool =
    var rect = parent[RectComponentData]
    var dest = newRect(rect.position, rect.size)
    this.element.draw(dest)
  
  proc eventUpdate(dt: float32): bool =
    var rect = parent[RectComponentData]
    var dest = newRect(rect.position, rect.size)
    discard this.element.update(dest,
        this.mousePos, dt)

  proc eventResize(data: void): bool =
    var rect = parent[RectComponentData]
    var dest = newRect(rect.position, rect.size)

  proc setUIActive(value: bool) =
    this.element.isActive = value

  proc isUIActive(): bool =
    this.element.isActive


  proc construct(elements: seq[UIElement], active: bool = true) =
    this.element = elements[0]
    this.element.isActive = active
