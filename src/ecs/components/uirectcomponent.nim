import core/templates
import ecs/types
import ecs/component
import core/events

import ui/types/uirectangle
import core/types/vector2
import core/types/rect
import rectcomponent

type
  UIRectComponentData* = ref object of ComponentData
    rect*: UIRectangle
    children*: seq[ptr Entity]
    prect*: Rect
    root: bool

method updateRectComponent*(this: ptr Entity, prect: Rect)

method updateRectComponent*(this: ptr Entity) =
  let bounds = this[UIRectComponentData].rect.toRect(this[UIRectComponentData].prect)
  this[RectComponentData].size = bounds.size
  this[RectComponentData].position = bounds.location
  for child in this[UIRectComponentData].children:
    updateRectComponent(child, bounds)

method updateRectComponent*(this: ptr Entity, prect: Rect) =
  this[UIRectComponentData].prect = prect
  this.updateRectComponent()

proc resizeUIRectComponent(parent: ptr Entity, data: pointer): bool =
  var this = parent[UIRectComponentData]
  var size = cast[ptr tuple[w, h: int32]](data)[]
  if this.root:
    updateRectComponent(parent, newRect(0, 0, size.w.float32, size.h.float32))

proc newUIRectComponent*(parentPtr: ref Entity, rect: UIRectangle): Component =
  return Component(
    dataType: "UIRectComponentData",
    targetLinks:
    @[
      ComponentLink(event: EVENT_RESIZE, p: resizeUIRectComponent),
      ComponentLink(event: EVENT_INIT, p: proc(parent: ptr Entity, data: pointer): bool =
        parent[UIRectComponentData] = UIRectComponentData()
        parent[UIRectComponentData].rect = rect
        if addr(parentPtr[]) == nil:
          parent[UIRectComponentData].root = true
          return
        addr(parentPtr[])[UIRectComponentData].children &= parent
      ),
    ]
  )
