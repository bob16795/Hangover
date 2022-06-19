import core/templates
import ecs/types
import ecs/component
import core/events

import ui/types/uirectangle
import core/types/vector2
import core/types/rect
import rectcomponent

import ecs/genmacros

{.experimental: "codeReordering".}

component UIRectComponent:
  var
    rect: UIRectangle
    children: seq[ptr Entity]
    prect: Rect
    root: bool

  proc updateRectComponent() =
    let bounds = this.rect.toRect(this.prect)
    parent[RectComponentData].size = bounds.size
    parent[RectComponentData].position = bounds.location
    for child in this.children:
      child[UIRectComponentData].prect = bounds
      updateRectComponent(child)

  proc eventResize(size: tuple[w, h: int32]): bool =
    if this.root:
      this.prect = newRect(0, 0, size.w.float32, size.h.float32)
      parent.updateRectComponent()

  proc construct(parentPtr: ref Entity,
                 rect: UIRectangle) =
    this.rect = rect
    if addr(parentPtr[]) == nil:
      this.root = true
      return
    addr(parentPtr[])[UIRectComponentData].children &= parent
