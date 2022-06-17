import core/types/vector2
import core/types/rect
import ecs/types
import ecs/component
import core/templates
import sugar

type
  RectComponentData* = ref object of ComponentData
    size*, position*: Vector2

proc newRectComponent*(dest: Rect): Component =
  Component(
    dataType: "RectComponentData",
    targetLinks:
    @[
      ComponentLink(event: EVENT_INIT, p: proc(parent: ptr Entity, data: pointer): bool =
        parent[RectComponentData] = RectComponentData()
        parent[RectComponentData].size = dest.size
        parent[RectComponentData].position = dest.location
      ),
    ]
  )
