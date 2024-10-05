import hangover/core/types/vector2
import hangover/core/types/rect
import hangover/core/events
import hangover/ui/uimanager
import hangover/ecs/genmacros
import hangover/ecs/entity
import hangover/ecs/component
import hangover/ecs/types
import hangover/core/templates
import hangover/ecs/components/rectcomponent

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
    this.element.checkHover(newRect(rect.position, rect.size), this.mousePos)
    if this.drag != nil:
      this.drag.drag(this.last, true)

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
    this.element.update(dest,
        this.mousePos, dt, true)

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
